//
//  UserDefaultsDiff.swift
//  DebugSwift
//
//  Created by Matheus Gois (Defaults Diff) on 16/07/26.
//

import Foundation

// MARK: - UserDefaults Diff & Undo

/// An abstraction over `UserDefaults` so the diff logic can be tested with an
/// in-memory dictionary stand-in. `UserDefaults.standard` conforms via an
/// extension in the UIKit adapter.
public protocol DefaultsStore: AnyObject {
    func allKeys() -> Set<String>
    func value(for key: String) -> Any?
    func set(_ value: Any?, for key: String)
}

/// An in-memory `DefaultsStore` for testing.
public final class InMemoryDefaults: DefaultsStore {
    private var store: [String: Any]

    public init(_ initial: [String: Any] = [:]) {
        store = initial
    }

    public func allKeys() -> Set<String> {
        Set(store.keys)
    }

    public func value(for key: String) -> Any? {
        store[key]
    }

    public func set(_ value: Any?, for key: String) {
        if let value {
            store[key] = value
        } else {
            store.removeValue(forKey: key)
        }
    }
}

/// A single detected change between a snapshot and the current state.
public struct DefaultsChange: Equatable {
    public enum Kind: Equatable {
        case added
        case modified
        case removed
    }

    public let key: String
    public let kind: Kind
    public let oldValue: Any?
    public let newValue: Any?

    public init(key: String, kind: Kind, oldValue: Any?, newValue: Any?) {
        self.key = key
        self.kind = kind
        self.oldValue = oldValue
        self.newValue = newValue
    }

    public static func == (lhs: DefaultsChange, rhs: DefaultsChange) -> Bool {
        guard lhs.key == rhs.key, lhs.kind == rhs.kind else { return false }
        return String(describing: lhs.oldValue) == String(describing: rhs.oldValue)
            && String(describing: lhs.newValue) == String(describing: rhs.newValue)
    }
}

/// Snapshot a `DefaultsStore` and compute added/modified/removed changes,
/// with the ability to undo a single change.
public final class UserDefaultsDiff {

    private let store: DefaultsStore
    private var snapshot: [String: Any] = [:]

    public init(store: DefaultsStore) {
        self.store = store
    }

    /// Capture the current state as the baseline for future diffs.
    public func snapshotNow() {
        snapshot = currentDict()
    }

    /// Compute changes since the last snapshot.
    public func diff() -> [DefaultsChange] {
        let current = currentDict()
        let oldKeys = Set(snapshot.keys)
        let newKeys = Set(current.keys)
        var changes: [DefaultsChange] = []

        for key in newKeys.subtracting(oldKeys) {
            changes.append(DefaultsChange(key: key, kind: .added, oldValue: nil, newValue: current[key]))
        }
        for key in oldKeys.subtracting(newKeys) {
            changes.append(DefaultsChange(key: key, kind: .removed, oldValue: snapshot[key], newValue: nil))
        }
        for key in oldKeys.intersection(newKeys) where !equal(snapshot[key], current[key]) {
            changes.append(DefaultsChange(key: key, kind: .modified, oldValue: snapshot[key], newValue: current[key]))
        }
        return changes
    }

    /// Restore the store to its pre-change state for a single change.
    public func undo(_ change: DefaultsChange) {
        switch change.kind {
        case .added:
            store.set(nil, for: change.key)
        case .removed, .modified:
            store.set(change.oldValue, for: change.key)
        }
    }

    // MARK: - Private

    private func currentDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        for key in store.allKeys() {
            if let value = store.value(for: key) {
                dict[key] = value
            }
        }
        return dict
    }

    private func equal(_ lhs: Any?, _ rhs: Any?) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}
