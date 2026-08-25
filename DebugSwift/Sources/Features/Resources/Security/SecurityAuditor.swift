//
//  SecurityAuditor.swift
//  DebugSwift
//
//  Created by Matheus Gois (Security Audit) on 16/07/26.
//

import Foundation

// MARK: - Secure Storage Audit

/// A single finding from a secure-storage audit.
public struct SecurityFinding: Equatable {
    public enum Severity: String, Equatable {
        case info
        case warning
        case critical
    }

    public enum Source: String, Equatable {
        case userDefaults
        case infoPlist
        case bundle
        case keychain
    }

    public let severity: Severity
    public let source: Source
    public let key: String
    public let message: String

    public init(severity: Severity, source: Source, key: String, message: String) {
        self.severity = severity
        self.source = source
        self.key = key
        self.message = message
    }
}

/// Heuristic auditor that scans dictionaries/arrays (the real sources are read
/// once and passed in) for sensitive-data exposure. Key-name matching and
/// file-extension checks are pure string operations — fully testable on macOS.
public struct SecurityAuditor {

    public var sensitivePatterns: [String]

    public init(sensitivePatterns: [String] = [
        "key", "secret", "token", "password", "apikey", "api_key"
    ]) {
        self.sensitivePatterns = sensitivePatterns
    }

    /// Audit the four sources for sensitive-data exposure.
    public func audit(
        userDefaults: [String: Any],
        infoPlist: [String: Any],
        bundleFiles: [String],
        keychainItems: [String: String]
    ) -> [SecurityFinding] {
        var findings: [SecurityFinding] = []
        let lowercasedPatterns = sensitivePatterns.map { $0.lowercased() }

        // UserDefaults: sensitive key with a non-empty string value.
        for (key, value) in userDefaults where isSensitive(key.lowercased(), patterns: lowercasedPatterns) {
            if let value = value as? String, !value.isEmpty {
                findings.append(SecurityFinding(
                    severity: .warning,
                    source: .userDefaults,
                    key: key,
                    message: "Sensitive key in UserDefaults with non-empty value"
                ))
            }
        }

        // Info.plist: sensitive key with a non-empty string value.
        for (key, value) in infoPlist where isSensitive(key.lowercased(), patterns: lowercasedPatterns) {
            if let value = value as? String, !value.isEmpty {
                findings.append(SecurityFinding(
                    severity: .warning,
                    source: .infoPlist,
                    key: key,
                    message: "Sensitive key in Info.plist"
                ))
            }
        }

        // Bundle: dangerous credential file extensions.
        let dangerousExtensions = [".cer", ".p12", ".mobileconfig", ".pem", ".key"]
        for file in bundleFiles where dangerousExtensions.contains(where: { file.hasSuffix($0) }) {
            findings.append(SecurityFinding(
                severity: .critical,
                source: .bundle,
                key: file,
                message: "Credential file in app bundle"
            ))
        }

        // Keychain: weak accessibility attributes.
        for (key, attribute) in keychainItems {
            if attribute.contains("AfterFirstUnlock") || attribute.contains("Always") {
                findings.append(SecurityFinding(
                    severity: .info,
                    source: .keychain,
                    key: key,
                    message: "Keychain item uses weak accessibility: \(attribute)"
                ))
            }
        }

        return findings
    }

    // MARK: - Private

    private func isSensitive(_ key: String, patterns: [String]) -> Bool {
        patterns.contains { key.contains($0) }
    }
}
