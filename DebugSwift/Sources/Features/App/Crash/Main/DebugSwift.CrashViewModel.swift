//
//  CrashViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation
import UIKit

final class CrashViewModel: NSObject {
    var data: [CrashModel] {
        (
            CrashManager.shared.recover(ofType: .nsexception) +
                CrashManager.shared.recover(ofType: .signal)
        ).sorted(by: { $0.details.date > $1.details.date })
    }

    // MARK: - ViewModel

    func viewTitle() -> String {
        "Crashes"
    }

    func numberOfItems() -> Int {
        data.count
    }

    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let trace = data[index]
        return (
            title: trace.details.name,
            value: "\n     \(trace.details.date.formatted())"
        )
    }

    func handleClearAction() {
        CrashManager.shared.deleteAll(ofType: .nsexception)
        CrashManager.shared.deleteAll(ofType: .signal)
    }

    func handleDeleteItemAction(atIndex index: Int) {
        let crash = data[index]
        CrashManager.shared.delete(crash: crash)
    }

    func emptyListDescriptionString() -> String {
        "No data found in the " + viewTitle()
    }
}
