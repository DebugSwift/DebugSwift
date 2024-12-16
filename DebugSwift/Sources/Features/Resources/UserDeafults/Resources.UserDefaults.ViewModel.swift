//
//  Resources.UserDefaults.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

final class ResourcesUserDefaultsViewModel: NSObject, ResourcesGenericListViewModel {
    private var keys = [String]()

    // MARK: - Initialization

    override init() {
        super.init()
        setupKeys()
    }

    private func setupKeys() {
        keys = UserDefaults.standard.dictionaryRepresentation().keys.sorted()
        if let latitudeIndex = keys.firstIndex(
            of: LocationToolkit.Constants.simulatedLatitude
        ) {
            keys.remove(at: latitudeIndex)
        }
        if let longitudeIndex = keys.firstIndex(
            of: LocationToolkit.Constants.simulatedLongitude
        ) {
            keys.remove(at: longitudeIndex)
        }
    }

    // MARK: - ViewModel

    var isSearchActived = false

    var reloadData: (() -> Void)?

    func viewTitle() -> String {
        "User defaults"
    }

    func numberOfItems() -> Int {
        isSearchActived ? filteredKeys.count : keys.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let key = isSearchActived ? filteredKeys[index] : keys[index]
        let value = "\(UserDefaults.standard.object(forKey: key) ?? "")"
        return .init(title: key, value: value)
    }

    func handleClearAction() {
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        keys.removeAll()
        filteredKeys.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        let key = isSearchActived ? filteredKeys.remove(at: index) : keys.remove(at: index)
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()

        if isSearchActived {
            keys.removeAll(where: { $0 == key })
        }
    }

    func emptyListDescriptionString() -> String {
        "empty-data".localized() + "User Defaults"
    }

    // MARK: - Search Functionality

    private var filteredKeys = [String]()

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredKeys = keys
        } else {
            filteredKeys = keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
