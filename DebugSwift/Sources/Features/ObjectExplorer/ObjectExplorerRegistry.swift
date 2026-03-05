//
//  ObjectExplorerRegistry.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025.
//

import Foundation

@MainActor
public final class ObjectExplorerRegistry {
    public static let shared = ObjectExplorerRegistry()
    private init() {}

    struct Entry {
        let name: String
        let objectProvider: @MainActor () -> Any?
    }

    private(set) var entries: [Entry] = []

    public func register(name: String, objectProvider: @escaping @MainActor () -> Any?) {
        entries.append(Entry(name: name, objectProvider: objectProvider))
    }

    public func removeAll() {
        entries.removeAll()
    }
}
