//
//  DebugSwift.ObjectExplorer.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025.
//

import Foundation

extension DebugSwift {
    @MainActor
    public class ObjectExplorer {
        /// Register a custom object for inspection in the Object Explorer.
        /// - Parameters:
        ///   - name: Display name for the object in the explorer list.
        ///   - objectProvider: A closure that returns the object to inspect.
        public static func register(name: String, objectProvider: @escaping @MainActor () -> Any?) {
            ObjectExplorerRegistry.shared.register(name: name, objectProvider: objectProvider)
        }

        /// Remove all custom registered objects.
        public static func removeAll() {
            ObjectExplorerRegistry.shared.removeAll()
        }
    }
}
