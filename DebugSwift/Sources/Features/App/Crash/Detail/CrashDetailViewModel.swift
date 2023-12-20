//
//  CrashDetailViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import UIKit
import Foundation

class CrashDetailViewModel: NSObject {

    private(set) var data: CrashModel

    init(data: CrashModel) {
        self.data = data
    }

    // MARK: - ViewModel

    func viewTitle() -> String {
        "actions-crash".localized()
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
            .init(title: "Name", detail: data.details.name),
            .init(title: "Date", detail: data.details.date.formatted()),
            .init(title: "App Version", detail: data.details.appVersion ?? ""),
            .init(title: "App Build", detail: data.details.appBuild ?? ""),
            .init(title: "System Version", detail: data.details.iosVersion)
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
        var result = "Details:\n"
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
