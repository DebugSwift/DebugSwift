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
    private var keychainItems = [(service: String, key: String)]()
    private var keychain = Keychain()

    // MARK: - Initialization

    override init() {
        super.init()
        setupKeys()
    }

    private func setupKeys() {
        // Get all keychain items regardless of service
        keychainItems = Keychain.allKeys(.genericPassword)
        
        // Remove location-related keys that DebugSwift uses internally
        keychainItems.removeAll { item in
            item.key == LocationToolkit.Constants.simulatedLatitude ||
            item.key == LocationToolkit.Constants.simulatedLongitude
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
        isSearchActived ? filteredItems.count : keychainItems.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let item = isSearchActived ? filteredItems[index] : keychainItems[index]
        let value = getKeychainValue(for: item) ?? ""
        return .init(title: item.key, value: value)
    }
    
    private func getKeychainValue(for item: (service: String, key: String)) -> String? {
        // Create keychain instance with the specific service to retrieve the value
        let serviceKeychain = Keychain(service: item.service)
        return try? serviceKeychain.get(item.key)
    }

    func handleClearAction() {
        // Remove items from all services
        let uniqueServices = Set(keychainItems.map { $0.service })
        for service in uniqueServices {
            let serviceKeychain = Keychain(service: service)
            try? serviceKeychain.removeAll()
        }
        keychainItems.removeAll()
        filteredItems.removeAll()
    }

    func handleDeleteItemAction(atIndex index: Int) {
        let item = isSearchActived ? filteredItems.remove(at: index) : keychainItems.remove(at: index)
        let serviceKeychain = Keychain(service: item.service)
        try? serviceKeychain.remove(item.key)

        if isSearchActived {
            keychainItems.removeAll(where: { $0.service == item.service && $0.key == item.key })
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
        let item = isSearchActived ? filteredItems[index] : keychainItems[index]
        let value = getKeychainValue(for: item) ?? ""
        
        return .init(
            key: item.key,
            value: value,
            keyPlaceholder: "Enter keychain item name",
            valuePlaceholder: "Enter secure value",
            title: "Edit Keychain Item"
        )
    }

    func updateItem(atIndex index: Int, key: String, value: String) {
        let currentItem = isSearchActived ? filteredItems[index] : keychainItems[index]
        let serviceKeychain = Keychain(service: currentItem.service)
        
        do {
            // If key changed, remove the old key
            if currentItem.key != key {
                try serviceKeychain.remove(currentItem.key)
            }
            
            // Set the new value (using the same service as the original item)
            try serviceKeychain.set(value, key: key)
            
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
        var exportDict = [String: Any]()
        
        for item in keychainItems {
            if let value = getKeychainValue(for: item) {
                // Include service information in the export for clarity
                exportDict[item.key] = [
                    "value": value,
                    "service": item.service
                ]
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

    private var filteredItems = [(service: String, key: String)]()

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredItems = keychainItems
        } else {
            filteredItems = keychainItems.filter { 
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                $0.service.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func keyExists(_ key: String) -> Bool {
        return keychainItems.contains { $0.key == key }
    }
}
