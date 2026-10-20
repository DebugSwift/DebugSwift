//
//  SignalCrashReport.swift
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

import Foundation
#if canImport(DebugSwiftSignalCapture)
internal import DebugSwiftSignalCapture
#endif

/// Converts the low-level protocol record at the boundary, only during normal execution.
struct SignalCrashReport {
    let signal: Int32
    let crash: CrashModel

    init(data: Data) throws {
        guard data.count == MemoryLayout<DSSignalCrashRecord>.size else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var record = DSSignalCrashRecord()
        _ = withUnsafeMutableBytes(of: &record) { data.copyBytes(to: $0) }
        guard DSSignalCrashRecordIsValid(&record) != 0 else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let metadata = withUnsafeBytes(of: record.metadata) {
            Data($0.prefix(Int(record.metadataLength)))
        }
        let captured = try JSONDecoder().decode(SignalCrashMetadata.self, from: metadata)
        signal = record.signalNumber
        let name = "Signal \(Self.signalName(signal))"
        let details = captured.makeDetails(
            name: name,
            date: Date(timeIntervalSince1970: TimeInterval(record.timestamp))
        )
        var traces: [CrashModel.Trace] = []
        if record.instructionAddress != 0 {
            traces.append(Self.trace(record.instructionAddress, image: record.instructionImage, label: "Program counter"))
        }
        if record.linkRegister != 0 {
            traces.append(Self.trace(record.linkRegister, image: record.linkImage, label: "Link register"))
        }
        crash = CrashModel(
            type: .signal,
            details: details,
            context: .init(
                image: nil,
                consoleOutput: "",
                errorOutput: "Signal code: \(record.signalCode)\nFault address: \(Self.address(record.faultAddress))"
                    + "\nStack pointer: \(Self.address(record.stackPointer))"
                    + "\nFrame pointer: \(Self.address(record.framePointer))"
            ),
            traces: traces,
            captureID: captured.captureID
        )
    }

    private static func address(_ value: UInt64) -> String {
        "0x" + String(value, radix: 16)
    }

    private static func trace(_ address: UInt64, image raw: DSSignalImage, label: String) -> CrashModel.Trace {
        var image: CrashModel.BinaryImage?
        if withUnsafeBytes(of: raw.uuid, { $0.contains { $0 != 0 } }) {
            let candidate = CrashModel.BinaryImage(
                uuid: UUID(uuid: raw.uuid),
                loadAddress: raw.loadAddress,
                preferredAddress: raw.preferredAddress,
                textSize: raw.textSize
            )
            if candidate.normalizedAddress(for: address) != nil {
                image = candidate
            }
        }
        return .init(title: Self.address(address), detail: label, address: address, image: image)
    }

    private static func signalName(_ signal: Int32) -> String {
        switch signal {
        case SIGABRT: return "SIGABRT"
        case SIGBUS: return "SIGBUS"
        case SIGFPE: return "SIGFPE"
        case SIGILL: return "SIGILL"
        case SIGPIPE: return "SIGPIPE"
        case SIGSEGV: return "SIGSEGV"
        case SIGSYS: return "SIGSYS"
        case SIGTRAP: return "SIGTRAP"
        default: return "Unknown"
        }
    }
}
