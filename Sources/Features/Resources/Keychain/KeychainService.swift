//
//  KeychainService.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

final class KeychainService {

    private(set) var keychainValues = [String: Any]()
    private(set) var keychainKeys = [String]()

    // MARK: - Initialization

    init() {
        setupKeychainValues()
    }

    // MARK: - Public Methods

    func getValue(forKey key: String) -> String? {
        if let value = keychainValues[key] {
            return "\(value)"
        }
        return nil
    }

    func removeValue(for key: String) {
        var searchDictionary = [String: Any]()
        if let encodedKey = key.data(using: .utf8) {
            searchDictionary[kSecAttrAccount as String] = encodedKey
            let secItemClasses = self.secItemClasses()
            for secItemClass in secItemClasses {
                searchDictionary[kSecClass as String] = secItemClass
                SecItemDelete(searchDictionary as CFDictionary)
            }
        }
    }

    func setValue(_ value: Any, forKey key: String) {
        keychainValues[key] = value
        saveToKeychain(key: key, value: value)
    }

    // MARK: - Private methods

    private func saveToKeychain(key: String, value: Any) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: convertToData(value)
        ]

        SecItemDelete(query as CFDictionary) // Delete existing item with the same key if it exists

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Debug.print("Error saving to Keychain. Status: \(status)")
        }
    }

    private func convertToData(_ value: Any) -> Data {
        if let data = value as? Data {
            return data
        } else if let string = value as? String {
            return Data(string.utf8)
        } else if let number = value as? NSNumber {
            var value = number.doubleValue
            return Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        } else if let object = value as? NSCoding {
            return try! NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
        }
        fatalError("Unsupported value type")
    }

    private func setupKeychainValues() {
        keychainValues.removeAll()
        keychainKeys.removeAll()

        var query: [String: Any] = [
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnData as String: kCFBooleanTrue!
        ]

        let secItemClasses = self.secItemClasses()

        for secItemClass in secItemClasses {
            query[kSecClass as String] = secItemClass
            var result: AnyObject?

            if SecItemCopyMatching(query as CFDictionary, &result) != errSecItemNotFound {
                if let dictionaries = result as? [[String: Any]] {
                    for dictionary in dictionaries {
                        var account: String
                        if let accountObject = dictionary[kSecAttrAccount as String] as? Data,
                           let decodedAccount = String(data: accountObject, encoding: .utf8) {
                            account = decodedAccount
                        } else {
                            account = dictionary[kSecAttrAccount as String] as? String ?? ""
                        }

                        if let data = dictionary[kSecValueData as String] as? Data, data.count > 0, account.count > 0 {
                            var unarchivedObject: Any?
                            do {
                                unarchivedObject = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data)
                            } catch {
                                // Do nothing.
                            }
                            let decodedString = String(data: data, encoding: .utf8)
                            keychainValues[account] = unarchivedObject ?? (decodedString ?? data)
                        }
                    }
                }
            }

            if result != nil {
                result = nil
            }
        }

        keychainKeys = Array(keychainValues.keys).sorted(by: { $0.compare($1) == .orderedAscending })
    }

    private func secItemClasses() -> [Any] {
        return [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
    }
}
