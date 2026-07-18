//
//  UserDefaultsDiffAdapter.swift
//  DebugSwift
//
//  Created by Matheus Gois (Defaults Diff) on 16/07/26.
//

import Foundation

// MARK: - UserDefaults Diff & Undo

/// `UserDefaults.standard` conformance to `DefaultsStore`, enabling the pure
/// `UserDefaultsDiff` to operate against the real store.
extension UserDefaults: DefaultsStore {

    public func allKeys() -> Set<String> {
        Set(dictionaryRepresentation().keys)
    }

    public func value(for key: String) -> Any? {
        object(forKey: key)
    }

    public func set(_ value: Any?, for key: String) {
        if let value {
            set(value, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }
}

/// Convenience wrapper that snapshots `UserDefaults.standard` at launch and
/// exposes diff/undo for the Resources tab.
final class UserDefaultsDiffAdapter: @unchecked Sendable {

    static let shared = UserDefaultsDiffAdapter()

    private let diff: UserDefaultsDiff

    private init() {
        diff = UserDefaultsDiff(store: UserDefaults.standard)
    }

    /// Capture the current state as the baseline. Call from `setup()`.
    func snapshotNow() {
        diff.snapshotNow()
    }

    /// Compute changes since the snapshot.
    func changes() -> [DefaultsChange] {
        diff.diff()
    }

    /// Restore a single change.
    func undo(_ change: DefaultsChange) {
        diff.undo(change)
    }
}
