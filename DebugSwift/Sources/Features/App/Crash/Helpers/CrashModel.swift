//
//  CrashModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import UIKit

struct CrashModel: Codable, Equatable {
    let captureID: UUID?
    let type: CrashType
    let details: Details
    let context: Context
    let traces: [Trace]

    init(
        type: CrashType,
        details: Details,
        context: Context = .builder(),
        traces: [Trace],
        captureID: UUID? = nil
    ) {
        self.captureID = captureID
        self.type = type
        self.details = details
        self.context = context
        self.traces = traces
    }

    static func == (lhs: CrashModel, rhs: CrashModel) -> Bool {
        if lhs.captureID != nil || rhs.captureID != nil {
            return lhs.captureID == rhs.captureID
        }
        return lhs.details.name == rhs.details.name
    }
}

extension CrashModel {
    struct Details: Codable {
        let name: String
        let date: Date
        let appVersion: String?
        let appBuild: String?
        let iosVersion: String
        let deviceModel: String
        let reachability: String

        static func builder(name: String) -> Self {
            if Thread.isMainThread {
                return MainActor.assumeIsolated {
                    .init(
                        name: name,
                        date: .init(),
                        appVersion: UserInfo.getAppVersionInfo()?.detail,
                        appBuild: UserInfo.getAppBuildInfo()?.detail,
                        iosVersion: UserInfo.getIOSVersionInfo().detail,
                        deviceModel: UserInfo.getDeviceModelInfo().detail,
                        reachability: UserInfo.getReachability().detail
                    )
                }
            } else {
                // When not on main thread, we can't access main actor isolated properties
                return .init(
                    name: name,
                    date: .init(),
                    appVersion: UserInfo.getAppVersionInfo()?.detail,
                    appBuild: UserInfo.getAppBuildInfo()?.detail,
                    iosVersion: "Unknown",
                    deviceModel: "Unknown",
                    reachability: UserInfo.getReachability().detail
                )
            }
        }
    }
}

extension CrashModel {
    struct Context: Codable {
        let image: Data?
        let consoleOutput: String
        let errorOutput: String

        var uiImage: UIImage? {
            guard let image else { return nil }
            return UIImage(data: image)
        }

        static func builder() -> Self {
            if Thread.isMainThread {
                return MainActor.assumeIsolated {
                    .init(
                        image: UIWindow.keyWindow?._snapshotWithTouch?.pngData(),
                        consoleOutput: ConsoleOutput.shared.printAndNSLogOutputFormatted(),
                        errorOutput: ConsoleOutput.shared.errorOutputFormatted()
                    )
                }
            } else {
                // When not on main thread, we can't capture the snapshot
                return .init(
                    image: nil,
                    consoleOutput: ConsoleOutput.shared.printAndNSLogOutputFormatted(),
                    errorOutput: ConsoleOutput.shared.errorOutputFormatted()
                )
            }
        }
    }
}

extension CrashModel {
    struct Trace: Codable {
        let title: String
        let detail: String
        let address: UInt64?
        let image: BinaryImage?

        init(title: String, detail: String, address: UInt64? = nil, image: BinaryImage? = nil) {
            self.title = title
            self.detail = detail
            self.address = address
            self.image = image
        }

        var info: UserInfo.Info {
            .init(title: title, detail: detail)
        }
    }
}

extension CrashModel {
    struct BinaryImage: Codable, Equatable {
        let uuid: UUID
        let loadAddress: UInt64
        let preferredAddress: UInt64
        let textSize: UInt64

        func normalizedAddress(for address: UInt64) -> UInt64? {
            guard address >= loadAddress else { return nil }
            let offset = address - loadAddress
            guard offset < textSize, offset <= UInt64.max - preferredAddress else { return nil }
            return preferredAddress + offset
        }
    }
}

extension [CrashModel.Trace] {
    static func builder(_ stack: [String]) -> [CrashModel.Trace] {
        var traces = [CrashModel.Trace]()

        for symbol in stack {
            let trace = CrashModel.Trace(
                title: symbol,
                detail: ""
            )
            traces.append(trace)
        }

        return traces
    }
}
