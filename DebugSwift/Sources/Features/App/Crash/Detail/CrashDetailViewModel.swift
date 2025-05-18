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

    init(data: CrashModel) {
        self.data = data
        Debug.print(data.details.name)
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
        for trace in data.traces {
            result += "\(trace.info)\n"
        }

        return result
    }
}
