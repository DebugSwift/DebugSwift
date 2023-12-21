//
//  CrashModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import UIKit

struct CrashModel: Codable, Equatable {
    let type: CrashType
    let details: Details
    let context: Context
    let traces: [Trace]

    init(
        type: CrashType,
        details: Details,
        context: Context = .builder(),
        traces: [Trace] = .builder()
    ) {
        self.type = type
        self.details = details
        self.context = context
        self.traces = traces
    }

    static func == (lhs: CrashModel, rhs: CrashModel) -> Bool {
        lhs.details.name == rhs.details.name
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

        static func builder(name: String) -> Self {
            .init(
                name: name,
                date: .init(),
                appVersion: UserInfo.getAppVersionInfo()?.detail,
                appBuild: UserInfo.getAppBuildInfo()?.detail,
                iosVersion: UserInfo.getIOSVersionInfo().detail,
                deviceModel: UserInfo.getDeviceModelInfo().detail
            )
        }
    }
}

extension CrashModel {
    struct Context: Codable {
        let image: Data?
        let consoleOutput: String

        var uiImage: UIImage? {
            guard let image else { return nil }
            return UIImage(data: image)
        }

        static func builder() -> Self {
            .init(
                image: UIWindow.keyWindow?._snapshotWithTouch?.pngData(),
                consoleOutput: LogIntercepter.shared.consoleOutput.reversed().joined(separator: "\n")
            )
        }
    }
}

extension CrashModel {
    struct Trace: Codable {
        let title: String
        let detail: String

        var info: UserInfo.Info {
            .init(title: title, detail: detail)
        }
    }
}

extension [CrashModel.Trace] {
    static func builder() -> Self {
        var traces = [CrashModel.Trace]()
        for symbol in Thread.callStackSymbols {
            var detail = ""
            if let className = Trace.classNameFromSymbol(symbol) {
                detail += "Class: \(className)\n"
            }
            if let fileInfo = Trace.fileInfoFromSymbol(symbol) {
                detail += """
                    File: \(fileInfo.file)\n,
                    Line: \(fileInfo.line)\n,
                    Function: \(fileInfo.function)\n
                """
            }

            let trace = CrashModel.Trace(
                title: symbol,
                detail: detail
            )
            traces.append(trace)
        }

        return traces
    }
}
