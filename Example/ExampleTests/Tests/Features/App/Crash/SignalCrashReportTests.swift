//
//  SignalCrashReportTests.swift
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

import DebugSwiftSignalCapture
import XCTest
@testable import DebugSwift

final class SignalCrashReportTests: XCTestCase {
    private let imageUUID = UUID(uuidString: "1267CCDA-81C1-4821-958A-883732693482")!

    private func makeRecord(captureID: UUID = UUID()) throws -> DSSignalCrashRecord {
        let details = CrashModel.Details(
            name: "",
            date: .distantPast,
            appVersion: "previous-launch-version",
            appBuild: "42",
            iosVersion: "27.0",
            deviceModel: "captured-device",
            reachability: "WiFi"
        )
        let metadata = try JSONEncoder().encode(SignalCrashMetadata(details: details, captureID: captureID))
        var record = DSSignalCrashRecord()
        record.magic = DS_SIGNAL_RECORD_MAGIC
        record.version = DS_SIGNAL_RECORD_VERSION
        record.signalNumber = SIGSEGV
        record.signalCode = 1
        record.timestamp = 1_790_000_000
        record.faultAddress = 0xdead
        record.instructionAddress = 0x1234
        record.stackPointer = 0x5678
        record.linkRegister = 0xabcd
        record.metadataLength = UInt32(metadata.count)
        _ = withUnsafeMutableBytes(of: &record.metadata) { metadata.copyBytes(to: $0) }
        return record
    }

    private func data(_ record: DSSignalCrashRecord) -> Data {
        withUnsafeBytes(of: record) { Data($0) }
    }

    private func mappedRecord() throws -> DSSignalCrashRecord {
        var record = try makeRecord()
        record.instructionAddress = 0x1_0030_1234
        record.instructionImage.loadAddress = 0x1_0030_0000
        record.instructionImage.preferredAddress = 0x1_0000_0000
        record.instructionImage.textSize = 0x10000
        record.instructionImage.uuid = imageUUID.uuid
        return record
    }

    private func loadSymbols(imageUUID: UUID?, file: String = "App.swift", line: Int = 10) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var map: [String: Any] = [
            "loadAddress": UInt64(0x1_0000_0000),
            "symbols": [
                ["address": UInt64(0x1_0000_1000), "name": "actualFault", "file": file, "line": line],
                ["address": UInt64(0x1_0000_2000), "name": "unrelatedLastSymbol", "file": "Other.swift", "line": 30]
            ]
        ]
        if let imageUUID { map["imageUUID"] = imageUUID.uuidString }
        try JSONSerialization.data(withJSONObject: map).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertTrue(SymbolicatorAdapter.shared.load(from: url.path))
    }

    private func withStore(_ body: (CrashManager, URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(CrashType.signal.fileName))
            try? FileManager.default.removeItem(at: directory)
        }
        try body(CrashManager(directory: directory), directory)
    }

    func testRecoveryUsesOriginalMetadataAndFaultRegisters() throws {
        let record = try makeRecord()
        let report = try SignalCrashReport(data: data(record))

        XCTAssertEqual(report.signal, SIGSEGV)
        XCTAssertEqual(report.crash.type, .signal)
        XCTAssertEqual(report.crash.details.name, "Signal SIGSEGV")
        XCTAssertEqual(report.crash.details.date.timeIntervalSince1970, TimeInterval(record.timestamp))
        XCTAssertEqual(report.crash.details.appVersion, "previous-launch-version")
        XCTAssertEqual(report.crash.details.deviceModel, "captured-device")
        XCTAssertNotNil(report.crash.captureID)
        XCTAssertEqual(report.crash.traces.map(\.title), ["0x1234", "0xabcd"])
        XCTAssertTrue(report.crash.context.errorOutput.contains("Fault address: 0xdead"))
        XCTAssertNil(report.crash.context.image)
        XCTAssertTrue(report.crash.context.consoleOutput.isEmpty)
    }

    func testRejectsTruncatedUnknownAndOversizedRecords() throws {
        var record = try makeRecord()
        XCTAssertThrowsError(try SignalCrashReport(data: Data(data(record).dropLast())))
        record.version += 1
        XCTAssertThrowsError(try SignalCrashReport(data: data(record)))
        record = try makeRecord()
        record.metadataLength = DS_SIGNAL_METADATA_CAPACITY + 1
        XCTAssertThrowsError(try SignalCrashReport(data: data(record)))
        record = try makeRecord()
        record.signalNumber = SIGUSR1
        XCTAssertThrowsError(try SignalCrashReport(data: data(record)))
    }

    func testMissingRegistersDoNotCreateInventedStackFrames() throws {
        var record = try makeRecord()
        record.instructionAddress = 0
        record.linkRegister = 0
        let report = try SignalCrashReport(data: data(record))
        XCTAssertTrue(report.crash.traces.isEmpty)
    }

    func testPendingRecordIsConsumedOnlyAfterSuccessfulPersistence() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let bytes = data(try makeRecord())
        try bytes.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(try SignalCrashCapture.recoverPending(at: url) { _ in
            throw CocoaError(.fileWriteOutOfSpace)
        })
        XCTAssertEqual(try Data(contentsOf: url), bytes)

        var persisted: CrashModel?
        let report = try SignalCrashCapture.recoverPending(at: url) { persisted = $0 }
        XCTAssertEqual(persisted?.details.date, report?.crash.details.date)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        var calledAgain = false
        XCTAssertNil(try SignalCrashCapture.recoverPending(at: url) { _ in calledAgain = true })
        XCTAssertFalse(calledAgain)
    }

    func testEmptyPendingFileDoesNotProduceAReport() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertNil(try SignalCrashCapture.recoverPending(at: url) { _ in XCTFail("Unexpected report") })
    }

    func testInvalidPendingRecordIsPreservedWithoutBlockingFutureCapture() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("pending.bin")
        let bytes = Data([1, 2, 3])
        try bytes.write(to: url)
        XCTAssertNil(try SignalCrashCapture.recoverPending(at: url) { _ in XCTFail("Unexpected report") })
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let preserved = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(preserved.count, 1)
        let invalid = try XCTUnwrap(preserved.first)
        XCTAssertEqual(try Data(contentsOf: invalid), bytes)
        try FileManager.default.removeItem(at: invalid)
        try FileManager.default.removeItem(at: directory)
    }

    func testOriginalImageNormalizesASLRBeforeSymbolication() throws {
        let record = try mappedRecord()
        let report = try SignalCrashReport(data: data(record))
        let frame = try XCTUnwrap(report.crash.traces.first)
        XCTAssertEqual(frame.address, record.instructionAddress)
        XCTAssertEqual(frame.image?.uuid, imageUUID)
        XCTAssertEqual(frame.image?.normalizedAddress(for: record.instructionAddress), 0x1_0000_1234)
        try loadSymbols(imageUUID: imageUUID)
        let result = SymbolicatorAdapter.shared.symbolicate(traces: report.crash.traces)
        XCTAssertEqual(result.first, "actualFault  App.swift:10")
        // The LR has no known image; it must retain its original address and its place.
        XCTAssertEqual(result.last, "0xabcd")
    }

    func testDifferentBuildAndUnidentifiedSymbolMapsKeepRawAddresses() throws {
        let report = try SignalCrashReport(data: data(mappedRecord()))
        try loadSymbols(imageUUID: UUID())
        XCTAssertEqual(SymbolicatorAdapter.shared.symbolicate(traces: report.crash.traces), report.crash.traces.map(\.title))
        try loadSymbols(imageUUID: nil)
        XCTAssertEqual(SymbolicatorAdapter.shared.symbolicate(traces: report.crash.traces), report.crash.traces.map(\.title))
    }

    func testMapWithoutSourceLocationsStillShowsFunctionNames() throws {
        let report = try SignalCrashReport(data: data(mappedRecord()))
        try loadSymbols(imageUUID: imageUUID, file: "", line: 0)
        XCTAssertEqual(SymbolicatorAdapter.shared.symbolicate(traces: report.crash.traces).first, "actualFault")
    }

    func testMissingInvalidAndOutOfRangeImagesDoNotGuessSymbols() throws {
        try loadSymbols(imageUUID: imageUUID)
        var record = try mappedRecord()
        record.instructionImage.textSize = 1
        var report = try SignalCrashReport(data: data(record))
        XCTAssertNil(report.crash.traces.first?.image)
        XCTAssertEqual(SymbolicatorAdapter.shared.symbolicate(traces: report.crash.traces), report.crash.traces.map(\.title))
        record = try mappedRecord()
        record.instructionImage.uuid = DSSignalImage().uuid
        report = try SignalCrashReport(data: data(record))
        XCTAssertNil(report.crash.traces.first?.image)
    }

    func testPlainTextFramesArePreservedWhenAMapIsLoaded() throws {
        try loadSymbols(imageUUID: imageUUID)
        let frames = [CrashModel.Trace(title: "App.Controller.didTap()", detail: "")]
        XCTAssertEqual(SymbolicatorAdapter.shared.symbolicate(traces: frames), frames.map(\.title))
    }

    func testRecoveryReplayAfterJSONCommitDoesNotDuplicateTheReport() throws {
        try withStore { store, _ in
            let pending = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try data(makeRecord()).write(to: pending)
            defer { try? FileManager.default.removeItem(at: pending) }
            XCTAssertThrowsError(try SignalCrashCapture.recoverPending(at: pending) { crash in
                try store.persist(crash: crash)
                // Same persistent state as interruption after JSON commit but before consuming pending.
                throw CocoaError(.userCancelled)
            })
            let first = store.recover(ofType: .signal)
            XCTAssertEqual(first.count, 1)
            XCTAssertTrue(FileManager.default.fileExists(atPath: pending.path))
            let replayed = try SignalCrashCapture.recoverPending(at: pending) { try store.persist(crash: $0) }
            XCTAssertEqual(store.recover(ofType: .signal).count, 1)
            XCTAssertEqual(replayed?.crash.captureID, first.first?.captureID)
            XCTAssertFalse(FileManager.default.fileExists(atPath: pending.path))
        }
    }

    func testDistinctCapturesWithIdenticalSignalAndTimeRemainDistinct() throws {
        try withStore { store, _ in
            let first = try SignalCrashReport(data: data(makeRecord())).crash
            let second = try SignalCrashReport(data: data(makeRecord())).crash
            XCTAssertNotEqual(first, second)
            XCTAssertEqual(first.details.name, second.details.name)
            XCTAssertEqual(first.details.date, second.details.date)
            try store.persist(crash: first)
            try store.persist(crash: second)
            XCTAssertEqual(store.recover(ofType: .signal).count, 2)
            store.delete(crash: first)
            XCTAssertEqual(store.recover(ofType: .signal).map(\.captureID), [second.captureID])
        }
    }

    func testCorruptHistoryIsPreservedAndPendingRecoveryCanFinish() throws {
        try withStore { store, directory in
            let url = directory.appendingPathComponent(CrashType.signal.fileName)
            let corrupted = Data("existing unreadable report".utf8)
            try corrupted.write(to: url)
            let pending = directory.appendingPathComponent("pending.bin")
            try data(makeRecord()).write(to: pending)
            defer { try? FileManager.default.removeItem(at: pending) }

            let report = try SignalCrashCapture.recoverPending(at: pending) { try store.persist(crash: $0) }
            XCTAssertNotNil(report)
            XCTAssertFalse(FileManager.default.fileExists(atPath: pending.path))
            XCTAssertEqual(store.recover(ofType: .signal).map(\.captureID), [report?.crash.captureID])
            let preserved = try quarantinedHistory(in: directory)
            defer { try? FileManager.default.removeItem(at: preserved) }
            XCTAssertEqual(try Data(contentsOf: preserved), corrupted)
        }
    }

    func testViewingCorruptHistoryQuarantinesItOnlyOnce() throws {
        try withStore { store, directory in
            let url = directory.appendingPathComponent(CrashType.signal.fileName)
            let corrupted = Data("[{\"type\":\"signal\"}]".utf8)
            try corrupted.write(to: url)
            XCTAssertTrue(store.recover(ofType: .signal).isEmpty)
            let preserved = try quarantinedHistory(in: directory)
            defer { try? FileManager.default.removeItem(at: preserved) }
            XCTAssertEqual(try Data(contentsOf: preserved), corrupted)
            XCTAssertTrue(store.recover(ofType: .signal).isEmpty)
            XCTAssertEqual(try quarantinedHistory(in: directory), preserved)
            let crash = try SignalCrashReport(data: data(makeRecord())).crash
            try store.persist(crash: crash)
            XCTAssertEqual(store.recover(ofType: .signal).map(\.captureID), [crash.captureID])
        }
    }

    func testHistoryReadFailurePreservesPendingAndIsNotQuarantined() throws {
        try withStore { store, directory in
            let url = directory.appendingPathComponent(CrashType.signal.fileName)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            let pending = directory.appendingPathComponent("pending.bin")
            let bytes = data(try makeRecord())
            try bytes.write(to: pending)
            defer { try? FileManager.default.removeItem(at: pending) }
            XCTAssertThrowsError(try SignalCrashCapture.recoverPending(at: pending) { try store.persist(crash: $0) })
            XCTAssertEqual(try Data(contentsOf: pending), bytes)
            XCTAssertTrue(try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).isEmpty)
            // Once the actual I/O problem is resolved, the same pending record is retried.
            try FileManager.default.removeItem(at: url)
            XCTAssertNotNil(try SignalCrashCapture.recoverPending(at: pending) { try store.persist(crash: $0) })
            XCTAssertEqual(store.recover(ofType: .signal).count, 1)
        }
    }

    func testHistoryWriteFailurePreservesPendingForRetry() throws {
        try withStore { _, directory in
            let destination = directory.appendingPathComponent("not-created-yet")
            let store = CrashManager(directory: destination)
            let pending = directory.appendingPathComponent("pending.bin")
            let bytes = data(try makeRecord())
            try bytes.write(to: pending)
            defer { try? FileManager.default.removeItem(at: pending) }
            XCTAssertThrowsError(try SignalCrashCapture.recoverPending(at: pending) { try store.persist(crash: $0) })
            XCTAssertEqual(try Data(contentsOf: pending), bytes)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
            defer {
                try? FileManager.default.removeItem(at: destination.appendingPathComponent(CrashType.signal.fileName))
                try? FileManager.default.removeItem(at: destination)
            }
            XCTAssertNotNil(try SignalCrashCapture.recoverPending(at: pending) { try store.persist(crash: $0) })
            XCTAssertEqual(store.recover(ofType: .signal).count, 1)
        }
    }

    private func quarantinedHistory(in directory: URL) throws -> URL {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix(CrashType.signal.fileName + ".invalid-") }
        XCTAssertEqual(files.count, 1)
        return try XCTUnwrap(files.first)
    }

    func testOlderCrashJSONStillDecodesWithoutCaptureAndImageFields() throws {
        let crash = try SignalCrashReport(data: data(makeRecord())).crash
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(crash)) as? [String: Any])
        object.removeValue(forKey: "captureID")
        object["traces"] = [["title": "existing frame", "detail": ""]]
        let decoded = try JSONDecoder().decode(CrashModel.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.captureID)
        XCTAssertNil(decoded.traces.first?.address)
        XCTAssertNil(decoded.traces.first?.image)
    }
}
