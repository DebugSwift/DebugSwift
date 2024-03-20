//
//  LocalizationViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/03/24.
//

import Foundation

final class LocalizationViewModel: NSObject, ResourcesGenericListViewModel {

    private var data: [String] { LocalizationManager.getAllLocalizations() }

    // MARK: - ViewModel

    var reloadData: (() -> Void)?

    var showSearch = false
    var isSearchActived: Bool = false
    var isDeleteEnable: Bool = false
    var isCustomActionEnable: Bool = true

    func viewTitle() -> String {
        "Localization"
    }

    func numberOfItems() -> Int {
        data.count
    }

    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let title = data[index]
        return (title: title, value: "")
    }

    func didTapItem(index: Int) {
        LocalizationManager.setLocalization(data[index])
    }

    func emptyListDescriptionString() -> String {
        "Localizations not found"
    }

    func handleClearAction() {}
    func handleDeleteItemAction(atIndex index: Int) {}
    func filterContentForSearchText(_ searchText: String) {}
}
