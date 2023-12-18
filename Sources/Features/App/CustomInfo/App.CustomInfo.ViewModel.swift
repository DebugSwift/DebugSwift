//
//  App.CustomInfo.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation

class AppCustomInfoViewModel: NSObject, ResourcesGenericListViewModel {

    enum Constants {
        static let simulatedLocationLatitude = "_simulatedLocationLatitude"
        static let simulatedLocationLongitude = "_simulatedLocationLongitude"
    }

    private var data: CustomData
    private var filteredInfo = [CustomData.Info]()

    // MARK: - Initialization

    init(data: CustomData) {
        self.data = data
        super.init()
    }

    // MARK: - ViewModel

    var isDeleteEnable: Bool { false }

    func viewTitle() -> String {
        data.title
    }

    func numberOfItems() -> Int {
        data.infos.count
    }

    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let info = data.infos[index]
        return (title: info.title, value: info.subtitle)
    }

    func handleClearAction() {}

    func handleDeleteItemAction(atIndex index: Int) {}

    func emptyListDescriptionString() -> String {
        "There are no \(data.title)"
    }

    // MARK: - Search Functionality

    private var filteredKeys = [String]()

    func numberOfFilteredItems() -> Int {
        filteredKeys.count
    }

    func filteredDataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let info = filteredInfo[index]
        return (title: info.title, value: info.subtitle)
    }

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
