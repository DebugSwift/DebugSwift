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

    var isEditEnable: Bool { true }

    var isAddEnable: Bool { true }

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

    func getAddItemData() -> ResourcesGenericController.EditItemData {
        return .init(
            key: nil,
            value: nil,
            keyPlaceholder: "Enter key name",
            valuePlaceholder: "Enter value",
            title: "Add UserDefaults Item"
        )
    }

    func getEditItemData(atIndex index: Int) -> ResourcesGenericController.EditItemData {
        let key = isSearchActived ? filteredKeys[index] : keys[index]
        let value = UserDefaults.standard.object(forKey: key)
        let stringValue = String(describing: value ?? "")
        
        return .init(
            key: key,
            value: stringValue,
            keyPlaceholder: "Enter key name",
            valuePlaceholder: "Enter value",
            title: "Edit UserDefaults Item"
        )
    }

    func updateItem(atIndex index: Int, key: String, value: String) {
        // Keys can't be changed in UserDefaults, so we just update the value
        let currentKey = isSearchActived ? filteredKeys[index] : keys[index]
        saveValue(value, forKey: currentKey)
        setupKeys()
    }

    func addItem(key: String, value: String) {
        saveValue(value, forKey: key)
        setupKeys()
    }

    private func saveValue(_ value: String, forKey key: String) {
        // Try to parse the value to appropriate type
        if let intValue = Int(value) {
            UserDefaults.standard.set(intValue, forKey: key)
        } else if let doubleValue = Double(value) {
            UserDefaults.standard.set(doubleValue, forKey: key)
        } else if let boolValue = Bool(value) {
            UserDefaults.standard.set(boolValue, forKey: key)
        } else if let data = value.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data) {
            UserDefaults.standard.set(jsonObject, forKey: key)
        } else {
            UserDefaults.standard.set(value, forKey: key)
        }
        
        UserDefaults.standard.synchronize()
    }

    func emptyListDescriptionString() -> String {
        "No data found in the " + "User Defaults"
    }

    func exportData() -> Data {
        var exportDict = [String: Any]()
        
        for key in keys {
            if let value = UserDefaults.standard.object(forKey: key) {
                exportDict[key] = convertToJSONCompatible(value)
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            return jsonData
        } catch {
            print("Export error: \(error)")
            return Data()
        }
    }
    
    private func convertToJSONCompatible(_ value: Any) -> Any {
        if let data = value as? Data {
            return data.base64EncodedString()
        } else if let dict = value as? [String: Any] {
            return sanitizeForJSON(dict)
        } else if let array = value as? [Any] {
            return array.map { convertToJSONCompatible($0) }
        } else {
            return value
        }
    }
    
    private func sanitizeForJSON(_ dict: [String: Any]) -> [String: Any] {
        var sanitized = [String: Any]()
        for (key, value) in dict {
            sanitized[key] = convertToJSONCompatible(value)
        }
        return sanitized
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
