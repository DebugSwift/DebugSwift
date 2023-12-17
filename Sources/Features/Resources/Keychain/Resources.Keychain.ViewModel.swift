//
//  Resources.Keychain.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import Security

class ResourcesKeychainViewModel: NSObject, ResourcesGenericListViewModel {
    enum Constants {
        static let simulatedLocationLatitude = "DBDebugToolkit_simulatedLocationLatitude"
        static let simulatedLocationLongitude = "DBDebugToolkit_simulatedLocationLongitude"
        static let keychainServiceName = "YourKeychainServiceName"
    }

    private var keys = [String]()
    private var keychain = KeychainService()

    // MARK: - Initialization

    override init() {
        super.init()
        setupKeys()
    }

    private func setupKeys() {
        keys = keychain.keychainKeys

        if let latitudeIndex = keys.firstIndex(of: Constants.simulatedLocationLatitude) {
            keys.remove(at: latitudeIndex)
        }
        if let longitudeIndex = keys.firstIndex(of: Constants.simulatedLocationLongitude) {
            keys.remove(at: longitudeIndex)
        }
    }

    // MARK: - DBTitleValueListViewModel

    func viewTitle() -> String {
        "Keychain"
    }

    func numberOfItems() -> Int {
        keys.count
    }

    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let key = keys[index]
        let value = keychain.getValue(forKey: key) ?? ""
        return (title: key, value: value)
    }

    func handleClearAction() {
        for key in keys {
            keychain.removeValue(for: key)
        }
        keys.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        let key = keys[index]
        keychain.removeValue(for: key)
        keys.remove(at: index)
    }

    func emptyListDescriptionString() -> String {
        "There are no entries in the Keychain."
    }

    // MARK: - Search Functionality

    private var filteredKeys = [String]()

    func numberOfFilteredItems() -> Int {
        filteredKeys.count
    }

    func filteredDataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let key = filteredKeys[index]
        let value = keychain.getValue(forKey: key) ?? ""
        return (title: key, value: value)
    }

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredKeys = keys
        } else {
            filteredKeys = keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
