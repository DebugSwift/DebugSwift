//
//  UserDefaultsAccessTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 21/12/2024.
//

import XCTest
@testable import DebugSwift

final class UserDefaultsAccessTests: XCTestCase {

    private var userDefaults: MockUserDefaults!
    private var keychain: MockKeychain!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
        keychain = MockKeychain()
    }

    override func tearDown() {
        userDefaults = nil
        keychain = nil
        super.tearDown()
    }

    func testUserDefaultAccessWithValidValue() {
        // Given
        let key = UserDefaults.Key.debugger
        let defaultValue = "default"
        let expectedValue = "storedValue"
        userDefaults.set(encodable: expectedValue, forKey: key.rawValue)
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: userDefaults)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        XCTAssertEqual(value, expectedValue, "The value should be the stored value")
    }

    func testUserDefaultAccessWithDefaultValue() {
        // Given
        let key = UserDefaults.Key.debugger
        let defaultValue = "default"
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: userDefaults)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        XCTAssertEqual(value, defaultValue, "The value should be the default value")
    }

    func testUserDefaultAccessSetValue() {
        // Given
        let key = UserDefaults.Key.debugger
        let defaultValue = "default"
        let newValue = "newValue"
        var userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: userDefaults)

        // When
        userDefaultAccess.wrappedValue = newValue

        // Then
        XCTAssertEqual(userDefaults.value(String.self, forKey: key.rawValue), newValue, "The value should be the new value")
    }

    func testKeychainAccessWithValidValue() {
        // Given
        let key = UserDefaults.Key.feedback
        let defaultValue = "default"
        let expectedValue = "storedValue"
        keychain.set(encodable: expectedValue, forKey: key.rawValue)
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: keychain)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        XCTAssertEqual(value, expectedValue, "The value should be the stored value")
    }

    func testKeychainAccessWithDefaultValue() {
        // Given
        let key = UserDefaults.Key.feedback
        let defaultValue = "default"
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: keychain)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        XCTAssertEqual(value, defaultValue, "The value should be the default value")
    }

    func testKeychainAccessSetValue() {
        // Given
        let key = UserDefaults.Key.feedback
        let defaultValue = "default"
        let newValue = "newValue"
        var userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: keychain)

        // When
        userDefaultAccess.wrappedValue = newValue

        // Then
        XCTAssertEqual(keychain.value(String.self, forKey: key.rawValue), newValue, "The value should be the new value")
    }
}

// MARK: - Mocks

class MockUserDefaults: UserDefaultsService {
    private var storage: [String: Data] = [:]

    func set<T: Encodable>(encodable: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(encodable) {
            storage[key] = data
        }
    }

    func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = storage[key] {
            return try? JSONDecoder().decode(type, from: data)
        }
        return nil
    }
}

class MockKeychain: UserDefaultsService {
    private var storage: [String: Data] = [:]

    func set<T: Encodable>(encodable: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(encodable) {
            storage[key] = data
        }
    }

    func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = storage[key] {
            return try? JSONDecoder().decode(type, from: data)
        }
        return nil
    }
}
