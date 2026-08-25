//
//  UserDefaultsDiffTests.swift
//  ExampleTests
//
//  Created by Matheus Gois on 16/07/26.
//

import XCTest
@testable import DebugSwift

final class UserDefaultsDiffTests: XCTestCase {

    // MARK: - Helpers

    private let prefix = "debugswift.test.diff."

    private func key(_ suffix: String) -> String {
        prefix + suffix
    }

    // MARK: - UserDefaultsDiff (InMemoryDefaults)

    func testDiff_addedKey() {
        let store = InMemoryDefaults([:])
        let diff = UserDefaultsDiff(store: store)
        diff.snapshotNow()

        store.set("new", for: key("added"))

        let changes = diff.diff()
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.key, key("added"))
        XCTAssertEqual(changes.first?.kind, .added)
        XCTAssertNil(changes.first?.oldValue)
        XCTAssertEqual(changes.first?.newValue as? String, "new")
    }

    func testDiff_modifiedKey() {
        let store = InMemoryDefaults([key("mod"): "old"])
        let diff = UserDefaultsDiff(store: store)
        diff.snapshotNow()

        store.set("new", for: key("mod"))

        let changes = diff.diff()
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.key, key("mod"))
        XCTAssertEqual(changes.first?.kind, .modified)
        XCTAssertEqual(changes.first?.oldValue as? String, "old")
        XCTAssertEqual(changes.first?.newValue as? String, "new")
    }

    func testDiff_removedKey() {
        let store = InMemoryDefaults([key("rem"): "value"])
        let diff = UserDefaultsDiff(store: store)
        diff.snapshotNow()

        store.set(nil, for: key("rem"))

        let changes = diff.diff()
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.key, key("rem"))
        XCTAssertEqual(changes.first?.kind, .removed)
        XCTAssertEqual(changes.first?.oldValue as? String, "value")
        XCTAssertNil(changes.first?.newValue)
    }

    func testDiff_noChanges() {
        let store = InMemoryDefaults([key("a"): 1, key("b"): 2])
        let diff = UserDefaultsDiff(store: store)
        diff.snapshotNow()

        let changes = diff.diff()
        XCTAssertTrue(changes.isEmpty)
    }

    func testUndo_added_removesKey() {
        let store = InMemoryDefaults([:])
        let diff = UserDefaultsDiff(store: store)
        diff.snapshotNow()

        store.set("new", for: key("added"))
        let change = diff.diff().first!
        diff.undo(change)

        XCTAssertNil(store.value(for: key("added")))
    }

    func testUndo_modified_restoresOldValue() {
        let store = InMemoryDefaults([key("mod"): "old"])
        let diff = UserDefaultsDiff(store: store)
        diff.snapshotNow()

        store.set("new", for: key("mod"))
        let change = diff.diff().first!
        diff.undo(change)

        XCTAssertEqual(store.value(for: key("mod")) as? String, "old")
    }

    func testUndo_removed_restoresKey() {
        let store = InMemoryDefaults([key("rem"): "value"])
        let diff = UserDefaultsDiff(store: store)
        diff.snapshotNow()

        store.set(nil, for: key("rem"))
        let change = diff.diff().first!
        diff.undo(change)

        XCTAssertEqual(store.value(for: key("rem")) as? String, "value")
    }

    func testInMemoryDefaults_allKeys() {
        let store = InMemoryDefaults([key("one"): 1, key("two"): 2])
        let keys = store.allKeys()
        XCTAssertEqual(keys.count, 2)
        XCTAssertTrue(keys.contains(key("one")))
        XCTAssertTrue(keys.contains(key("two")))
    }

    func testInMemoryDefaults_setNil_removesKey() {
        let store = InMemoryDefaults([key("gone"): "present"])
        store.set(nil, for: key("gone"))
        XCTAssertNil(store.value(for: key("gone")))
        XCTAssertFalse(store.allKeys().contains(key("gone")))
    }

    func testDefaultsChange_equatable() {
        let a = DefaultsChange(key: "k", kind: .added, oldValue: nil, newValue: "v")
        let b = DefaultsChange(key: "k", kind: .added, oldValue: nil, newValue: "v")
        let c = DefaultsChange(key: "k", kind: .modified, oldValue: nil, newValue: "v")
        let d = DefaultsChange(key: "other", kind: .added, oldValue: nil, newValue: "v")
        let e = DefaultsChange(key: "k", kind: .added, oldValue: nil, newValue: "different")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertNotEqual(a, d)
        XCTAssertNotEqual(a, e)
    }

    // MARK: - UserDefaultsDiffAdapter (UserDefaults.standard)

    func testShared_isNotNil() {
        XCTAssertNotNil(UserDefaultsDiffAdapter.shared)
    }

    func testSnapshotAndChanges_workflow() {
        let adapter = UserDefaultsDiffAdapter.shared
        let k = key("workflow")
        UserDefaults.standard.set(nil, forKey: k)

        adapter.snapshotNow()
        UserDefaults.standard.set("delta", forKey: k)

        let changes = adapter.changes()
        XCTAssertTrue(changes.contains(where: { $0.key == k && $0.kind == .added }))

        UserDefaults.standard.set(nil, forKey: k)
    }

    func testUndo_restoresValue() {
        let adapter = UserDefaultsDiffAdapter.shared
        let k = key("undo")
        UserDefaults.standard.set("baseline", forKey: k)

        adapter.snapshotNow()
        UserDefaults.standard.set("changed", forKey: k)

        let change = adapter.changes().first(where: { $0.key == k })!
        adapter.undo(change)

        XCTAssertEqual(UserDefaults.standard.string(forKey: k), "baseline")
        UserDefaults.standard.set(nil, forKey: k)
    }
}
