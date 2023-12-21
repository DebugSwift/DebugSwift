//
//  UserDefaultsAccess.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import Foundation

public protocol UserDefaultsService {
    func set<T: Encodable>(encodable: T, forKey key: String)
    func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T?
}

extension UserDefaults {
    enum Key: String {
        case debugger
    }
}

@propertyWrapper struct UserDefaultAccess<T: Codable> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaultsService

    init(
        key: UserDefaults.Key,
        defaultValue: T,
        userDefaults: UserDefaultsService = UserDefaults.standard
    ) {
        self.key = key.rawValue
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    public var wrappedValue: T {
        get { userDefaults.value(T.self, forKey: key) ?? defaultValue }
        set { userDefaults.set(encodable: newValue, forKey: key) }
    }
}

// MARK: - Extensions

extension UserDefaults: UserDefaultsService {
    public func set(encodable: some Encodable, forKey key: String) {
        if let data = try? JSONEncoder().encode(encodable) {
            set(data, forKey: key)
        }
    }

    public func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = object(forKey: key) as? Data {
            return try? JSONDecoder().decode(type, from: data)
        }
        return nil
    }
}

// MARK: - Extensions

extension Keychain: UserDefaultsService {
    public func set(encodable: some Encodable, forKey key: String) {
        if let data = try? JSONEncoder().encode(encodable) {
            try? set(data, key: key)
        }
    }

    public func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = try? getData(key),
           let value = try? JSONDecoder().decode(type, from: data) {
            return value
        }
        return nil
    }
}
