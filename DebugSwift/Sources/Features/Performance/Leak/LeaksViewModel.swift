//
//  LeaksViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/05/24.
//

import UIKit

final class LeaksViewModel: NSObject, ResourcesGenericListViewModel {

    private var data: [PerformanceLeakDetector.LeakModel] {
        PerformanceLeakDetector.leaks
    }
    private var filteredInfo = [PerformanceLeakDetector.LeakModel]()

    // MARK: - ViewModel

    var isSearchActived = false
    var reloadData: (() -> Void)?

    var isDeleteEnable: Bool { true }
    var isShareEnable: Bool { true }
    var isCustomActionEnable: Bool { true }

    func viewTitle() -> String { "leaks".localized() }

    func numberOfItems() -> Int {
        isSearchActived ? filteredInfo.count : data.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let leak = isSearchActived ? filteredInfo[index] : data[index]

        return .init(
            title: "\(leak.symbol)\(leak.details)",
            actionImage: leak.screenshot != nil ? .named("chevron.right", default: "action".localized()) : nil
        )
    }

    func handleClearAction() {
        PerformanceLeakDetector.leaks.removeAll()
        filteredInfo.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        if isSearchActived {
            let leak = filteredInfo.remove(at: index)
            PerformanceLeakDetector.leaks.removeAll(where: { $0.id == leak.id })
        } else {
            PerformanceLeakDetector.leaks.remove(at: index)
        }
    }

    func emptyListDescriptionString() -> String {
        "empty-data".localized() + "actions-console".localized()
    }

    func handleShareAction() {
        let allLeaks = PerformanceLeakDetector.leaks.reduce("", { $0 + "\n\n\($1.symbol)\($1.details)" })
        FileSharingManager.generateFileAndShare(text: allLeaks, fileName: "leaks")
    }

    // MARK: - Search Functionality

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredInfo = data
        } else {
            filteredInfo = data.filter {
                $0.details.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    func didTapItem(index: Int) {
        let leak = PerformanceLeakDetector.leaks[index]
        if let image = leak.screenshot {
            let controller = SnapshotViewController(
                title: "Leak",
                image: image,
                description: leak.details
            )
            UIApplication.topViewController()?.navigationController?.pushViewController(
                controller,
                animated: true
            )
        }
    }
}
