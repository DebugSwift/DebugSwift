//
//  App.CustomInfo.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation

final class AppCustomInfoViewModel: NSObject, ResourcesGenericListViewModel {
    private var data: CustomData
    private var filteredInfo = [CustomData.Info]()

    // MARK: - Initialization

    init(data: CustomData) {
        self.data = data
        super.init()
    }

    // MARK: - ViewModel

    var isSearchActived = false

    var reloadData: (() -> Void)?

    var isDeleteEnable: Bool { false }

    func viewTitle() -> String {
        data.title
    }

    func numberOfItems() -> Int {
        isSearchActived ? filteredInfo.count : data.infos.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let info = isSearchActived ? filteredInfo[index] : data.infos[index]
        return .init(title: info.title, value: info.subtitle)
    }

    func emptyListDescriptionString() -> String {
        "empty-data".localized() + data.title
    }

    // MARK: - Search Functionality

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredInfo = data.infos
        } else {
            filteredInfo = data.infos.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                    $0.subtitle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
