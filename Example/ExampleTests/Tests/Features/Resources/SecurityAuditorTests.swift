//
//  SecurityAuditorTests.swift
//  ExampleTests
//
//  Created by Matheus Gois on 16/07/26.
//

import XCTest
@testable import DebugSwift

final class SecurityAuditorTests: XCTestCase {

    // MARK: - Helpers

    private func makeAuditor(sensitivePatterns: [String]? = nil) -> SecurityAuditor {
        if let patterns = sensitivePatterns {
            return SecurityAuditor(sensitivePatterns: patterns)
        }
        return SecurityAuditor()
    }

    /// Empty inputs helper — all four sources empty.
    private func emptyInputs() -> (userDefaults: [String: Any], infoPlist: [String: Any], bundleFiles: [String], keychainItems: [String: String]) {
        return ([:], [:], [], [:])
    }

    // MARK: - SecurityFinding tests

    func testSecurityFinding_equatable() {
        let a = SecurityFinding(severity: .warning, source: .userDefaults, key: "api_key", message: "Sensitive key in UserDefaults with non-empty value")
        let b = SecurityFinding(severity: .warning, source: .userDefaults, key: "api_key", message: "Sensitive key in UserDefaults with non-empty value")
        XCTAssertEqual(a, b)

        // Different fields should not be equal.
        let c = SecurityFinding(severity: .critical, source: .bundle, key: "cert.cer", message: "Credential file in app bundle")
        XCTAssertNotEqual(a, c)
    }

    // MARK: - UserDefaults tests

    func testUserDefaults_sensitiveKeyWithNonEmptyValue_warns() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: ["api_key": "abc123"],
            infoPlist: [:],
            bundleFiles: [],
            keychainItems: [:]
        )
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.severity, .warning)
        XCTAssertEqual(findings.first?.source, .userDefaults)
        XCTAssertEqual(findings.first?.key, "api_key")
    }

    func testUserDefaults_sensitiveKeyWithEmptyValue_noFinding() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: ["api_key": ""],
            infoPlist: [:],
            bundleFiles: [],
            keychainItems: [:]
        )
        XCTAssertTrue(findings.isEmpty)
    }

    func testUserDefaults_nonSensitiveKey_noFinding() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: ["theme": "dark"],
            infoPlist: [:],
            bundleFiles: [],
            keychainItems: [:]
        )
        XCTAssertTrue(findings.isEmpty)
    }

    // MARK: - Info.plist tests

    func testInfoPlist_sensitiveKey_warns() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: ["APIKey": "secret"],
            bundleFiles: [],
            keychainItems: [:]
        )
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.severity, .warning)
        XCTAssertEqual(findings.first?.source, .infoPlist)
        XCTAssertEqual(findings.first?.key, "APIKey")
    }

    func testInfoPlist_nonSensitiveKey_noFinding() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: ["CFBundleName": "MyApp"],
            bundleFiles: [],
            keychainItems: [:]
        )
        XCTAssertTrue(findings.isEmpty)
    }

    // MARK: - Bundle tests

    func testBundle_credentialFile_critical() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: [:],
            bundleFiles: ["cert.cer"],
            keychainItems: [:]
        )
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.severity, .critical)
        XCTAssertEqual(findings.first?.source, .bundle)
        XCTAssertEqual(findings.first?.key, "cert.cer")
    }

    func testBundle_normalFile_noFinding() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: [:],
            bundleFiles: ["icon.png"],
            keychainItems: [:]
        )
        XCTAssertTrue(findings.isEmpty)
    }

    func testBundle_multipleDangerousExtensions() {
        let auditor = makeAuditor()
        let dangerousFiles = ["identity.p12", "private.pem", "signing.key", "profile.mobileconfig"]
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: [:],
            bundleFiles: dangerousFiles,
            keychainItems: [:]
        )
        XCTAssertEqual(findings.count, dangerousFiles.count)
        for finding in findings {
            XCTAssertEqual(finding.severity, .critical)
            XCTAssertEqual(finding.source, .bundle)
        }
        // Verify each file produced a finding.
        let reportedKeys = Set(findings.map { $0.key })
        XCTAssertEqual(reportedKeys, Set(dangerousFiles))
    }

    // MARK: - Keychain tests

    func testKeychain_weakAccessibility_info() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: [:],
            bundleFiles: [],
            keychainItems: ["myItem": "kSecAttrAccessibleAlways"]
        )
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.severity, .info)
        XCTAssertEqual(findings.first?.source, .keychain)
        XCTAssertEqual(findings.first?.key, "myItem")
    }

    func testKeychain_strongAccessibility_noFinding() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: [:],
            bundleFiles: [],
            keychainItems: ["myItem": "kSecAttrAccessibleWhenUnlocked"]
        )
        XCTAssertTrue(findings.isEmpty)
    }

    func testKeychain_afterFirstUnlock_info() {
        let auditor = makeAuditor()
        let findings = auditor.audit(
            userDefaults: [:],
            infoPlist: [:],
            bundleFiles: [],
            keychainItems: ["token": "kSecAttrAccessibleAfterFirstUnlock"]
        )
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.severity, .info)
        XCTAssertEqual(findings.first?.source, .keychain)
        XCTAssertEqual(findings.first?.key, "token")
    }

    // MARK: - Custom patterns

    func testCustomSensitivePatterns() {
        let auditor = makeAuditor(sensitivePatterns: ["passcode", "credential"])
        // Default patterns (key/secret/token/...) would NOT flag "mypasscode".
        let findings = auditor.audit(
            userDefaults: ["user_passcode": "1234", "credential_store": "abc"],
            infoPlist: [:],
            bundleFiles: [],
            keychainItems: [:]
        )
        XCTAssertEqual(findings.count, 2)
        XCTAssertEqual(findings.first?.source, .userDefaults)
        let reportedKeys = Set(findings.map { $0.key })
        XCTAssertEqual(reportedKeys, ["user_passcode", "credential_store"])
    }

    // MARK: - Empty inputs

    func testEmptyInputs_noFindings() {
        let auditor = makeAuditor()
        let inputs = emptyInputs()
        let findings = auditor.audit(
            userDefaults: inputs.userDefaults,
            infoPlist: inputs.infoPlist,
            bundleFiles: inputs.bundleFiles,
            keychainItems: inputs.keychainItems
        )
        XCTAssertTrue(findings.isEmpty)
    }

    // MARK: - SecurityAuditorAdapter

    func testAudit_returnsFindingsArray() {
        // The adapter reads real device sources. On a test host the result may
        // be empty, but it must be a valid array (not crash).
        let findings = SecurityAuditorAdapter.audit()
        XCTAssertEqual(findings.count, findings.count) // sanity — always true
        // Verify every finding is well-formed (non-empty key).
        for finding in findings {
            XCTAssertFalse(finding.key.isEmpty, "Findings should have non-empty keys")
        }
    }

    // MARK: - Integration: seeded sensitive UserDefaults

    func testAdapter_detectsSeededSensitiveUserDefaults() {
        let testKeys = ["test_api_key", "test_secret_token", "test_password"]
        // Seed sensitive values.
        for key in testKeys {
            UserDefaults.standard.set("sensitive-value-\(key)", forKey: key)
        }
        defer {
            for key in testKeys {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        let findings = SecurityAuditorAdapter.audit()
        let udFindings = findings.filter { $0.source == .userDefaults }
        let detectedKeys = Set(udFindings.map { $0.key })

        for key in testKeys {
            XCTAssertTrue(
                detectedKeys.contains(key),
                "Expected '\(key)' to be flagged as a sensitive UserDefaults key"
            )
        }
    }

    func testAdapter_noFindingsAfterRemovingSeededData() {
        let testKeys = ["test_api_key", "test_secret_token", "test_password"]
        // Seed then immediately remove.
        for key in testKeys {
            UserDefaults.standard.set("sensitive-value-\(key)", forKey: key)
        }
        for key in testKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        let findings = SecurityAuditorAdapter.audit()
        let udFindings = findings.filter { $0.source == .userDefaults }
        let detectedKeys = Set(udFindings.map { $0.key })

        for key in testKeys {
            XCTAssertFalse(
                detectedKeys.contains(key),
                "Removed key '\(key)' should not appear in findings"
            )
        }
    }

    func testAdapter_multipleSensitivePatterns_detected() {
        let testCases: [(String, String)] = [
            ("my_apikey", "abc"),
            ("oauth_token", "xyz"),
            ("user_secret", "pass"),
            ("admin_password", "123")
        ]
        for (key, value) in testCases {
            UserDefaults.standard.set(value, forKey: key)
        }
        defer {
            for (key, _) in testCases {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        let findings = SecurityAuditorAdapter.audit()
        let udFindings = findings.filter { $0.source == .userDefaults }
        let detectedKeys = Set(udFindings.map { $0.key })

        for (key, _) in testCases {
            XCTAssertTrue(
                detectedKeys.contains(key),
                "Expected '\(key)' to be flagged — it matches a sensitive pattern"
            )
        }
    }
}
