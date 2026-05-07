//
//  Resources.HTTPCookies.ViewModel.swift
//  DebugSwift
//
//  Created by nuomi1 on 2024-12-04.
//

import Foundation

final class ResourcesHTTPCookiesViewModel: NSObject, ResourcesGenericListViewModel {
    private struct Key: Equatable {
        var domain: String
        var name: String
    }

    private let storage = HTTPCookieStorage.shared
    private var keys: [Key] = []

    // MARK: - Initialization

    override init() {
        super.init()
        setupKeys()
    }

    private func setupKeys() {
        let sortOrder: [NSSortDescriptor] = [
            .init(keyPath: \HTTPCookie.domain, ascending: true),
            .init(keyPath: \HTTPCookie.name, ascending: true)
        ]
        keys = storage.sortedCookies(using: sortOrder).map { Key(domain: $0.domain, name: $0.name) }
    }

    // MARK: - ViewModel

    var isSearchActived: Bool = false

    var reloadData: (() -> Void)?

    func viewTitle() -> String {
        "HTTP Cookies"
    }

    func numberOfItems() -> Int {
        isSearchActived ? filteredKeys.count : keys.count
    }

    func dataSourceForItem(atIndex index: Int) -> ViewData {
        let key = isSearchActived ? filteredKeys[index] : keys[index]
        let value: String = {
            if let cookie = storage.cookies?.first(where: { $0.domain == key.domain && $0.name == key.name }) {
                return "\(cookie)"
            }
            return ""
        }()
        return .init(title: key.name, value: value)
    }

    func handleClearAction() {
        let keys = isSearchActived ? filteredKeys : self.keys
        removeItems(forKeys: keys)
    }

    func handleDeleteItemAction(atIndex index: Int) {
        let key = isSearchActived ? filteredKeys[index] : keys[index]
        removeItems(forKeys: [key])
    }

    private func removeItems(forKeys keys: [Key]) {
        var removedKeys: [Key] = []

        for key in keys {
            if let cookie = storage.cookies?.first(where: { $0.domain == key.domain && $0.name == key.name }) {
                storage.deleteCookie(cookie)
                removedKeys.append(key)
            }
        }

        filteredKeys.removeAll(where: { removedKeys.contains($0) })
        self.keys.removeAll(where: { removedKeys.contains($0) })
    }

    func emptyListDescriptionString() -> String {
        "No data found in the " + viewTitle()
    }

    // MARK: - Search Functionality

    private var filteredKeys: [Key] = []

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredKeys = keys
        } else {
            filteredKeys = keys.filter {
                $0.domain.localizedCaseInsensitiveContains(searchText)
                    || $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
