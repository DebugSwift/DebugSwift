//
//  ConsoleViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

final class AppConsoleViewModel: NSObject, ResourcesGenericListViewModel {

    private var data: [String] { ConsoleOutput.printAndNSLogOutput }

    private var filteredInfo = [String]()

    // MARK: - ViewModel

    var isSearchActived = false

    var reloadData: (() -> Void)?

    func viewTitle() -> String {
        "actions-console".localized()
    }

    func numberOfItems() -> Int {
        isSearchActived ? filteredInfo.count : data.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let info = isSearchActived ? filteredInfo[index] : data[index]
        return .init(title: info)
    }

    func handleClearAction() {
        ConsoleOutput.removeAll()
        filteredInfo.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        if isSearchActived {
            let info = filteredInfo.remove(at: index)
            ConsoleOutput.printAndNSLogOutput.removeAll(where: { $0 == info })
        } else {
            ConsoleOutput.printAndNSLogOutput.remove(at: index)
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
