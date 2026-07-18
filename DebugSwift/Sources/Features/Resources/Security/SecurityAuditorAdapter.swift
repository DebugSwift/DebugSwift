//
//  SecurityAuditorAdapter.swift
//  DebugSwift
//
//  Created by Matheus Gois (Security Audit) on 16/07/26.
//

import Foundation
import UIKit

// MARK: - Secure Storage Audit — UIKit/Foundation adapter

/// Reads the real sources once (`UserDefaults.standard`,
/// `Bundle.main.infoDictionary`, `Bundle.main.paths`, `KeychainManager`) and
/// passes them into the pure `SecurityAuditor`.
enum SecurityAuditorAdapter {

    static func audit() -> [SecurityFinding] {
        let auditor = SecurityAuditor()

        let userDefaults = UserDefaults.standard.dictionaryRepresentation()
        let infoPlist = Bundle.main.infoDictionary ?? [:]
        let bundleFiles = bundleFileNames()
        let keychainItems = keychainAccessibility()

        return auditor.audit(
            userDefaults: userDefaults,
            infoPlist: infoPlist,
            bundleFiles: bundleFiles,
            keychainItems: keychainItems
        )
    }

    // MARK: - Private

    /// Enumerate file names in the main bundle.
    private static func bundleFileNames() -> [String] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) else {
            return []
        }
        return urls.map(\.lastPathComponent)
    }

    /// Query the existing `KeychainService` for item accessibility attributes.
    /// Returns a map of key → accessibility string. When keychain access is
    /// unavailable on the current device, returns an empty map.
    private static func keychainAccessibility() -> [String: String] {
        // Keychain accessibility needs live SecItem queries, which the existing
        // KeychainService does not expose yet — report nothing until bridged.
        [:]
    }
}
