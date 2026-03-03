//
//  BodyEditorViewController.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 03/03/26.
//

import UIKit

final class BodyEditorViewController: BaseTableController {
    private let onSave: (String) -> Void

    private var editableJSONObject: Any
    private var items: [FlattenedItem] = []
    private var displayedItems: [FlattenedItem] = []
    private var searchText = ""
    private var searchRequestID: Int = 0

    init?(body: String, onSave: @escaping (String) -> Void) {
        guard let jsonObject = Self.parseJSONObjectOrArray(from: body) else {
            return nil
        }
        
        self.editableJSONObject = jsonObject
        self.onSave = onSave
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadItems()
    }

    private func setupUI() {
        title = "Edit JSON Body"
        view.backgroundColor = .black

        tableView.register(BodyKeyValueCell.self, forCellReuseIdentifier: "BodyKeyValueCell")
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .darkGray

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search keys and values..."
        search.hidesNavigationBarDuringPresentation = false

        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func reloadItems() {
        items = flatten(value: editableJSONObject)
        updateDisplayedItems(for: searchText)
    }

    @objc private func saveTapped() {
        guard JSONSerialization.isValidJSONObject(editableJSONObject),
              let data = try? JSONSerialization.data(withJSONObject: editableJSONObject, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            showAlert(with: "Failed to serialize edited JSON", title: "Error")
            return
        }

        onSave(json)
        navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BodyKeyValueCell", for: indexPath) as! BodyKeyValueCell
        let item = displayedItems[indexPath.row]
        cell.configure(key: item.displayKey, value: item.value)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = displayedItems[indexPath.row]
        showValueEditor(for: item)
    }

    private func showValueEditor(for item: FlattenedItem) {
        let alert = UIAlertController(title: item.displayKey, message: "Edit value", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = item.value
            textField.clearButtonMode = .whileEditing
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.smartQuotesType = .no
            textField.smartDashesType = .no
            textField.smartInsertDeleteType = .no
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let newValue = alert?.textFields?.first?.text else { return }
            self.applyEditedValue(newValue, at: item.pathTokens)
        })

        present(alert, animated: true)
    }

    private func applyEditedValue(_ rawValue: String, at pathTokens: [JSONPathToken]) {
        var root = editableJSONObject

        // Convert text input to a JSON-compatible value before writing it back.
        let parsedValue = parseEditableValue(rawValue)
        guard setJSONValue(&root, at: pathTokens, tokenIndex: 0, newValue: parsedValue) else {
            showAlert(with: "Failed to update value", title: "Error")
            return
        }

        editableJSONObject = root
        reloadItems()
    }

    private func updateDisplayedItems(for searchText: String) {
        searchRequestID += 1
        let requestID = searchRequestID

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            displayedItems = items
            tableView.reloadData()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self = self, self.searchRequestID == requestID else { return }
            let sourceItems = self.items
            DispatchQueue.global(qos: .userInitiated).async {
                let filteredItems = sourceItems.filter { $0.searchableText.contains(query) }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.searchRequestID == requestID else { return }
                    let currentQuery = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    guard currentQuery == query else { return }
                    self.displayedItems = filteredItems
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func flatten(
        value: Any,
        prefix: String = "",
        pathTokens: [JSONPathToken] = []
    ) -> [FlattenedItem] {
        var result: [FlattenedItem] = []
        
        switch value {
        case let dictionary as [String: Any]:
            for key in dictionary.keys.sorted() {
                let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
                if let child = dictionary[key] {
                    result.append(
                        contentsOf: flatten(
                            value: child,
                            prefix: fullKey,
                            pathTokens: pathTokens + [.key(key)]
                        )
                    )
                } else {
                    result.append(
                        FlattenedItem(
                            displayKey: fullKey,
                            value: "null",
                            pathTokens: pathTokens + [.key(key)],
                            searchableText: makeSearchableText(displayKey: fullKey, value: "null")
                        )
                    )
                }
            }
        case let array as [Any]:
            for (index, item) in array.enumerated() {
                let fullKey = prefix.isEmpty ? "[\(index)]" : "\(prefix)[\(index)]"
                result.append(
                    contentsOf: flatten(
                        value: item,
                        prefix: fullKey,
                        pathTokens: pathTokens + [.index(index)]
                    )
                )
            }
        default:
            // JSON booleans are bridged as NSNumber; treat them as true/false instead of 1/0.
            let valueString: String
            if let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() {
                valueString = number.boolValue ? "true" : "false"
            } else {
                valueString = "\(value)"
            }
            result.append(
                FlattenedItem(
                    displayKey: prefix,
                    value: valueString,
                    pathTokens: pathTokens,
                    searchableText: makeSearchableText(displayKey: prefix, value: valueString)
                )
            )
        }
        
        return result
    }

    private func setJSONValue(_ root: inout Any, at tokens: [JSONPathToken], tokenIndex: Int, newValue: Any) -> Bool {
        guard tokenIndex < tokens.count else {
            root = newValue
            return true
        }
        
        let current = tokens[tokenIndex]
        let isLeafToken = tokenIndex == tokens.count - 1

        switch current {
        case let .key(key):
            guard var dictionary = root as? [String: Any] else { return false }
            if isLeafToken {
                dictionary[key] = newValue
                root = dictionary
                return true
            }

            guard var nested = dictionary[key] else { return false }
            let didSet = setJSONValue(&nested, at: tokens, tokenIndex: tokenIndex + 1, newValue: newValue)
            guard didSet else { return false }
            dictionary[key] = nested
            root = dictionary
            return true

        case let .index(index):
            guard var array = root as? [Any], array.indices.contains(index) else { return false }
            if isLeafToken {
                array[index] = newValue
                root = array
                return true
            }

            var nested = array[index]
            let didSet = setJSONValue(&nested, at: tokens, tokenIndex: tokenIndex + 1, newValue: newValue)
            guard didSet else { return false }
            array[index] = nested
            root = array
            return true
        }
    }
    
    private static func parseJSONObjectOrArray(from body: String) -> Any? {
        let trimmedValue = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmedValue.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: []),
              // Body editor supports only top-level JSON object or array.
              object is [String: Any] || object is [Any] else {
            return nil
        }
        
        return object
    }
    
    private func parseEditableValue(_ rawValue: String) -> Any {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty { return "" }

        if trimmedValue == "null" {
            // JSON null is real value not nil
            return NSNull()
        }

        if trimmedValue == "true" {
            return true
        }

        if trimmedValue == "false" {
            return false
        }

        if let intValue = Int(trimmedValue) {
            return intValue
        }

        if let doubleValue = Double(trimmedValue) {
            return doubleValue
        }

        if let data = trimmedValue.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data, options: []),
           JSONSerialization.isValidJSONObject(object) {
            return object
        }

        return rawValue
    }

    private func makeSearchableText(displayKey: String, value: String) -> String {
        let keyComponents = displayKey.components(separatedBy: CharacterSet(charactersIn: ".[]"))
            .filter { !$0.isEmpty }
        return ([displayKey, value] + keyComponents)
            .joined(separator: " ")
            .lowercased()
    }
    
}

extension BodyEditorViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.searchText = searchController.searchBar.text ?? ""
        updateDisplayedItems(for: searchText)
    }
}

private enum JSONPathToken {
    case key(String)
    case index(Int)
}

private struct FlattenedItem {
    let displayKey: String
    let value: String
    let pathTokens: [JSONPathToken]
    let searchableText: String
}
