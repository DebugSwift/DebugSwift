//
//  SuperCallViolationsViewModel.swift
//  DebugSwift
//
//  View model for displaying missing-super-call violations detected by
//  ``SuperCallDetector``.  Follows the `LeaksViewModel` pattern.
//

import UIKit

final class SuperCallViolationsViewModel: NSObject, ResourcesGenericListViewModel {
    private var data: [SuperCallViolation] {
        SuperCallDetector.shared.violations
    }

    private var filteredInfo = [SuperCallViolation]()

    // MARK: - ViewModel

    var isSearchActivated = false
    var reloadData: (() -> Void)?

    var isDeleteEnable: Bool { false }
    var isCustomActionEnable: Bool { false }

    func viewTitle() -> String { "\(data.count) Super Call Violations" }

    func numberOfItems() -> Int {
        isSearchActivated ? filteredInfo.count : data.count
    }

    func dataSourceForItem(atIndex index: Int) -> ResourcesGenericController.CellViewData {
        let violation = isSearchActivated ? filteredInfo[index] : data[index]

        return .init(
            title: "🚨 \(violation.className) → \(violation.methodName)()",
            value: "Revealed by \(violation.revealedBy)()",
            actionImage: .named("chevron.right", default: "Action")
        )
    }

    func handleClearAction() {
        SuperCallDetector.shared.clearViolations()
        filteredInfo.removeAll()
    }


    func emptyListDescriptionString() -> String {
        "No super-call violations detected yet. Navigate your app to trigger lifecycle methods."
    }

    func handleShareAction() {
        let allViolations = SuperCallDetector.shared.violations.reduce("") { $0 + "\n\($1.message)" }
        FileSharingManager.generateFileAndShare(text: allViolations, fileName: "super-call-violations")
    }

    // MARK: - Search Functionality

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredInfo = data
        } else {
            filteredInfo = data.filter {
                $0.className.localizedCaseInsensitiveContains(searchText) ||
                $0.methodName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
