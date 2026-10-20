//
//  SignalCrashStorage.swift
//  DebugSwift
//
//  Created by gua on 2026/10/21.
//

import Foundation

/// Filesystem policy for raw pending records. Only used during normal startup;
/// the native signal handler receives an already protected, preopened file.
struct SignalCrashStorage: Sendable {
    static let protection = FileProtectionType.completeUntilFirstUserAuthentication
    static let shared = SignalCrashStorage(
        directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("DebugSwift/CrashReports", isDirectory: true),
        legacyPendingURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("pending_signal_crash.bin")
    )

    let directory: URL
    let legacyPendingURL: URL?

    var pendingURL: URL { directory.appendingPathComponent("pending_signal_crash.bin") }

    var recoveryURLs: [URL] {
        // Consume legacy records through normal validated recovery; never move one
        // over an existing destination record. Both survive persistence failures.
        [legacyPendingURL, pendingURL].compactMap { $0 }
    }

    func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Self.protect(directory, permissions: 0o700)
    }

    func preparePendingFile() throws {
        if !FileManager.default.fileExists(atPath: pendingURL.path) {
            // The caller has already recovered BOTH paths. Never truncate during
            // preparation: the native installer is the only owner of truncation.
            try Data().write(to: pendingURL, options: [.withoutOverwriting, .completeFileProtectionUntilFirstUserAuthentication])
        }
        try Self.protectRecord(pendingURL)
    }

    static func protectRecord(_ url: URL) throws {
        try protect(url, permissions: 0o600)
    }

    private static func protect(_ url: URL, permissions: Int) throws {
        try FileManager.default.setAttributes([
            .protectionKey: Self.protection,
            .posixPermissions: permissions
        ], ofItemAtPath: url.path)
        var target = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try target.setResourceValues(values)
    }
}
