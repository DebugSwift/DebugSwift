//
//  UserDefaultsAccessTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 21/12/2024.
//

import Testing
import Foundation
@testable import DebugSwift

struct UserDefaultsAccessTests {

    private let userDefaults: MockUserDefaults
    private let keychain: MockKeychain

    init() {
        userDefaults = MockUserDefaults()
        keychain = MockKeychain()
    }

    @Test("UserDefaults access with valid value")
    func userDefaultAccessWithValidValue() {
        // Given
        let key = UserDefaults.Key.debugger
        let defaultValue = "default"
        let expectedValue = "storedValue"
        userDefaults.set(encodable: expectedValue, forKey: key.rawValue)
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: userDefaults)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        #expect(value == expectedValue)
    }

    @Test("UserDefaults access with default value")
    func userDefaultAccessWithDefaultValue() {
        // Given
        let key = UserDefaults.Key.debugger
        let defaultValue = "default"
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: userDefaults)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        #expect(value == defaultValue)
    }

    @Test("UserDefaults access set value")
    func userDefaultAccessSetValue() {
        // Given
        let key = UserDefaults.Key.debugger
        let defaultValue = "default"
        let newValue = "newValue"
        var userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: userDefaults)

        // When
        userDefaultAccess.wrappedValue = newValue

        // Then
        #expect(userDefaults.value(String.self, forKey: key.rawValue) == newValue)
    }

    @Test("Keychain access with valid value")
    func keychainAccessWithValidValue() {
        // Given
        let key = UserDefaults.Key.feedback
        let defaultValue = "default"
        let expectedValue = "storedValue"
        keychain.set(encodable: expectedValue, forKey: key.rawValue)
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: keychain)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        #expect(value == expectedValue)
    }

    @Test("Keychain access with default value")
    func keychainAccessWithDefaultValue() {
        // Given
        let key = UserDefaults.Key.feedback
        let defaultValue = "default"
        let userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: keychain)

        // When
        let value = userDefaultAccess.wrappedValue

        // Then
        #expect(value == defaultValue)
    }

    @Test("Keychain access set value")
    func keychainAccessSetValue() {
        // Given
        let key = UserDefaults.Key.feedback
        let defaultValue = "default"
        let newValue = "newValue"
        var userDefaultAccess = UserDefaultAccess(key: key, defaultValue: defaultValue, userDefaults: keychain)

        // When
        userDefaultAccess.wrappedValue = newValue

        // Then
        #expect(keychain.value(String.self, forKey: key.rawValue) == newValue)
    }
}

// MARK: - Mocks

class MockUserDefaults: UserDefaultsService, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func set<T: Encodable>(encodable: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(encodable) {
            storage[key] = data
        }
    }

    func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

class MockKeychain: UserDefaultsService, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func set<T: Encodable>(encodable: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(encodable) {
            storage[key] = data
        }
    }

    func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
