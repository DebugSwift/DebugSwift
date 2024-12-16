//
//  App.CustomAction.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/01/24.
//

import Foundation

final class AppCustomActionViewModel: NSObject, ResourcesGenericListViewModel {
    private var data: CustomAction
    private var filtered = CustomAction.Actions()

    // MARK: - Initialization

    init(data: CustomAction) {
        self.data = data
        super.init()
    }

    // MARK: - ViewModel

    var isSearchActived = false
    var isDeleteEnable: Bool { false }
    var isCustomActionEnable: Bool { true }

    var reloadData: (() -> Void)?

    func viewTitle() -> String { data.title }

    func numberOfItems() -> Int {
        isSearchActived ? filtered.count : data.actions.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let info = isSearchActived ? filtered[index] : data.actions[index]
        return .init(title: info.title)
    }

    func emptyListDescriptionString() -> String {
        "empty-data".localized() + data.title
    }

    // MARK: - Search Functionality

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filtered = data.actions
        } else {
            filtered = data.actions.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Action

    func didTapItem(index: Int) {
        if isSearchActived {
            filtered[index].action?()
        } else {
            data.actions[index].action?()
        }
    }
}
