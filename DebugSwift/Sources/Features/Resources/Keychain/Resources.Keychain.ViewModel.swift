//
//  Resources.Keychain.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import Security

final class ResourcesKeychainViewModel: NSObject, ResourcesGenericListViewModel {
    private var keys = [String]()
    private var keychain = Keychain()

    // MARK: - Initialization

    override init() {
        super.init()
        setupKeys()
    }

    private func setupKeys() {
        keys = keychain.allKeys()

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

    var isEditEnable: Bool { true }

    var isAddEnable: Bool { true }

    func viewTitle() -> String {
        "Keychain"
    }

    func numberOfItems() -> Int {
        isSearchActived ? filteredKeys.count : keys.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let key = isSearchActived ? filteredKeys[index] : keys[index]
        let value = (try? keychain.get(key)) ?? ""
        return .init(title: key, value: value)
    }

    func handleClearAction() {
        try? keychain.removeAll()
        keys.removeAll()
        filteredKeys.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        let key = isSearchActived ? filteredKeys.remove(at: index) : keys.remove(at: index)
        try? keychain.remove(key)

        if isSearchActived {
            keys.removeAll(where: { $0 == key })
        }
    }

    func getAddItemData() -> ResourcesGenericController.EditItemData {
        return .init(
            key: nil,
            value: nil,
            keyPlaceholder: "Enter keychain item name",
            valuePlaceholder: "Enter secure value",
            title: "Add Keychain Item"
        )
    }

    func getEditItemData(atIndex index: Int) -> ResourcesGenericController.EditItemData {
        let key = isSearchActived ? filteredKeys[index] : keys[index]
        let value = (try? keychain.get(key)) ?? ""
        
        return .init(
            key: key,
            value: value,
            keyPlaceholder: "Enter keychain item name",
            valuePlaceholder: "Enter secure value",
            title: "Edit Keychain Item"
        )
    }

    func updateItem(atIndex index: Int, key: String, value: String) {
        let currentKey = isSearchActived ? filteredKeys[index] : keys[index]
        
        do {
            // If key changed, remove the old key
            if currentKey != key {
                try keychain.remove(currentKey)
            }
            
            // Set the new value
            try keychain.set(value, key: key)
            
            // Refresh keys
            setupKeys()
        } catch {
            print("Keychain error: \(error)")
        }
    }

    func addItem(key: String, value: String) {
        do {
            try keychain.set(value, key: key)
            setupKeys()
        } catch {
            print("Keychain error: \(error)")
        }
    }

    func emptyListDescriptionString() -> String {
        "No data found in the " + "Keychain"
    }

    func exportData() -> Data {
        var exportDict = [String: String]()
        
        for key in keys {
            if let value = try? keychain.get(key) {
                // Keychain values are already strings, but let's ensure they're valid for JSON
                exportDict[key] = value
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            return jsonData
        } catch {
            print("Keychain export error: \(error)")
            return Data()
        }
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
    
    func keyExists(_ key: String) -> Bool {
        return keys.contains(key)
    }
}
