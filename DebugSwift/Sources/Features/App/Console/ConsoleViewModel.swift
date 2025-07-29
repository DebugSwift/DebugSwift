//
//  ConsoleViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

final class AppConsoleViewModel: NSObject, ResourcesGenericListViewModel {
    private var data: [String] { ConsoleOutput.shared.getPrintAndNSLogOutput() }

    private var filteredInfo = [String]()

    // MARK: - ViewModel

    var isSearchActived = false

    var reloadData: (() -> Void)?

    func viewTitle() -> String {
        "Console"
    }

    func numberOfItems() -> Int {
        isSearchActived ? filteredInfo.count : data.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let info = isSearchActived ? filteredInfo[index] : data[index]
        return .init(title: info)
    }

    func handleClearAction() {
        ConsoleOutput.shared.removeAll()
        filteredInfo.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        if isSearchActived {
            let info = filteredInfo.remove(at: index)
            ConsoleOutput.shared.removeAllPrintAndNSLogOutput(info)
        } else {
            ConsoleOutput.shared.removePrintAndNSLogOutput(at: index)
        }
    }

    func emptyListDescriptionString() -> String {
        "No data found in the " + "Console"
    }

    func handleShareAction() {
        let allData = data.joined(separator: "\n")
        FileSharingManager.generateFileAndShare(text: allData, fileName: "console")
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
