//
//  ConsoleViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

final class AppConsoleViewModel: NSObject, ResourcesGenericListViewModel {

    private var data: [String] {
        LogIntercepter.shared.consoleOutput
    }

    private var filteredInfo = [String]()

    // MARK: - ViewModel

    var isSearchActived: Bool = false

    var reloadData: (() -> Void)?

    func viewTitle() -> String {
        "actions-console".localized()
    }

    func numberOfItems() -> Int {
        isSearchActived ? filteredInfo.count : data.count
    }

    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let info = isSearchActived ? filteredInfo[index] : data[index]
        return (title: info, value: "")
    }

    func handleClearAction() {
        LogIntercepter.shared.reset()
        filteredInfo.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        if isSearchActived {
            let info = filteredInfo.remove(at: index)
            LogIntercepter.shared.consoleOutput.removeAll(where: { $0 == info })
        } else {
            LogIntercepter.shared.consoleOutput.remove(at: index)
        }
    }

    func emptyListDescriptionString() -> String {
        "empty-data".localized() + "actions-console".localized()
    }

    // MARK: - Search Functionality

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredInfo = data
        } else {
            filteredInfo = data.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

extension AppConsoleViewModel: LogInterceptorDelegate {
    func logUpdated() {
        reloadData?()
    }
}
