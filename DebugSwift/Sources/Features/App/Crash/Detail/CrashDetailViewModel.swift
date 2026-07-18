//
//  CrashDetailViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import Foundation
import UIKit

final class CrashDetailViewModel: NSObject {
    private(set) var data: CrashModel

    /// Symbolicated descriptions for each trace, populated only when a symbol
    /// table is loaded. `nil` means raw traces should be shown as-is.
    private(set) var symbolicatedTraces: [String]?

    init(data: CrashModel) {
        self.data = data
        Debug.print(data.details.name)
    }

    /// Attempt to resolve raw frame strings into human-readable symbols via
    /// the shared `SymbolicatorAdapter`. No-op when no symbol table is loaded.
    func symbolicateTraces() {
        guard SymbolicatorAdapter.shared.isSymbolTableLoaded else { return }
        symbolicatedTraces = SymbolicatorAdapter.shared.symbolicate(traces: data.traces)
    }

    // MARK: - ViewModel

    func viewTitle() -> String {
        "Crashes"
    }

    func numberOfItems(section: Int) -> Int {
        switch CrashDetailViewController.Features(rawValue: section) {
        case .details:
            return details.count
        case .context:
            return contexts.count
        case .stackTrace:
            return data.traces.count
        default:
            return .zero
        }
    }

    var details: [UserInfo.Info] {
        [
            .init(
                title: "Error",
                detail: data.type.rawValue
            ),
            .init(
                title: "Date",
                detail: data.details.date.formatted()
            ),
            .init(
                title: "App Version:",
                detail: data.details.appVersion ?? ""
            ),
            .init(
                title: "Build Version:",
                detail: data.details.appBuild ?? ""
            ),
            .init(
                title: "iOS Version:",
                detail: data.details.iosVersion
            ),
            .init(
                title: "Device Model:",
                detail: data.details.deviceModel
            ),
            .init(
                title: "Connection Type:",
                detail: data.details.reachability
            ),
            .init(
                title: "Error",
                detail: data.details.name
            )
        ]
    }

    var contexts: [UserInfo.Info] {
        var infos = [UserInfo.Info]()
        if data.context.uiImage != nil {
            infos.append(.init(title: "Snapshot", detail: ""))
        }

        if !data.context.consoleOutput.isEmpty {
            infos.append(.init(title: "Logs", detail: ""))
        }

        if !data.context.errorOutput.isEmpty {
            infos.append(.init(title: "Error Log", detail: ""))
        }

        return infos
    }

    func dataSourceForItem(_ indexPath: IndexPath) -> UserInfo.Info? {
        switch CrashDetailViewController.Features(rawValue: indexPath.section) {
        case .details:
            return details[indexPath.row]
        case .context:
            return contexts[indexPath.row]
        case .stackTrace:
            if let symbolicated = symbolicatedTraces {
                return .init(title: symbolicated[indexPath.row], detail: data.traces[indexPath.row].detail)
            }
            return data.traces[indexPath.row].info
        default:
            return nil
        }
    }

    func getAllValues() -> String {
        var result = "Details" + ":\n"
        for detail in details {
            result += "\(detail.title): \(detail.detail)\n"
        }

        result += "\nStack Trace:\n"
        if let symbolicated = symbolicatedTraces {
            for line in symbolicated {
                result += "\(line)\n"
            }
        } else {
            for trace in data.traces {
                // Print the human-readable frame text, not the raw struct
                // description (which was "Info(title: \"…\", detail: \"…\")").
                let frame = trace.info.title
                let detail = trace.info.detail.isEmpty ? "" : " — \(trace.info.detail)"
                result += "\(frame)\(detail)\n"
            }
        }

        return result
    }
}
