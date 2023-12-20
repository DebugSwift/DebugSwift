//
//  ConsoleViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

class AppConsoleViewModel: NSObject, ResourcesGenericListViewModel {

    private var data: [String] {
        LogIntercepter.shared.consoleOutput
    }

    private var filteredInfo = [String]()

    // MARK: - ViewModel

    var reloadData: (() -> Void)?

    func viewTitle() -> String {
        "actions-console".localized()
    }

    func numberOfItems() -> Int {
        data.count
    }

    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let info = data[index]
        return (title: info, value: "")
    }

    func handleClearAction() {
        LogIntercepter.shared.reset()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        LogIntercepter.shared.consoleOutput.remove(at: index)
    }

    func emptyListDescriptionString() -> String {
        "empty-data".localized() + "actions-console".localized()
    }

    // MARK: - Search Functionality

    func numberOfFilteredItems() -> Int {
        filteredInfo.count
    }

    func filteredDataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let info = filteredInfo[index]
        return (title: info, value: "")
    }

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
