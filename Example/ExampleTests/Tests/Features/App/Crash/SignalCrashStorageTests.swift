//
//  SignalCrashStorageTests.swift
//  DebugSwift
//
//  Created by gua on 2026/10/21.
//

import Darwin
import DebugSwiftSignalCapture
import XCTest
@testable import DebugSwift

final class SignalCrashStorageTests: XCTestCase {
    private func withStorage(_ body: (SignalCrashStorage, CrashManager, URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        let storage = SignalCrashStorage(directory: root.appendingPathComponent("raw"), legacyPendingURL: root.appendingPathComponent("legacy.bin"))
        let history = root.appendingPathComponent("history")
        try FileManager.default.createDirectory(at: history, withIntermediateDirectories: false)
        defer {
            try? FileManager.default.removeItem(at: storage.pendingURL)
            try? FileManager.default.removeItem(at: root.appendingPathComponent("legacy.bin"))
            try? FileManager.default.removeItem(at: history.appendingPathComponent(CrashType.signal.fileName))
            _ = rmdir(storage.directory.path)
            _ = rmdir(history.path)
            _ = rmdir(root.path)
        }
        try body(storage, CrashManager(directory: history), root)
    }

    // Independent minimal migration payload: these tests concern file lifecycle,
    // not the richer fault-register/image fixtures in SignalCrashReportTests.
    private func writeRecord(at url: URL, captureID: UUID) throws -> Data {
        let details = CrashModel.Details(name: "", date: .distantPast, appVersion: "migration", appBuild: "1",
                                         iosVersion: "test", deviceModel: "test", reachability: "test")
        let metadata = try JSONEncoder().encode(SignalCrashMetadata(details: details, captureID: captureID))
        var record = DSSignalCrashRecord()
        record.magic = DS_SIGNAL_RECORD_MAGIC
        record.version = DS_SIGNAL_RECORD_VERSION
        record.signalNumber = SIGABRT
        record.timestamp = 1_790_000_000
        record.metadataLength = UInt32(metadata.count)
        _ = withUnsafeMutableBytes(of: &record.metadata) { metadata.copyBytes(to: $0) }
        let bytes = withUnsafeBytes(of: record) { Data($0) }
        try bytes.write(to: url)
        return bytes
    }

    func testPendingUsesPrivateApplicationSupportDirectory() {
        let storage = SignalCrashStorage.shared
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        XCTAssertEqual(storage.directory, support.appendingPathComponent("DebugSwift/CrashReports", isDirectory: true))
        XCTAssertNotEqual(storage.pendingURL.deletingLastPathComponent(), storage.legacyPendingURL?.deletingLastPathComponent())
    }

    func testProtectionAndBackupPolicyAreSetBeforeNativeInstall() throws {
        try withStorage { storage, store, _ in
            var installed = false
            let capture = SignalCrashCapture(storage: storage, manager: store) { url, _ in
                XCTAssertEqual(url, storage.pendingURL)
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                XCTAssertEqual(SignalCrashStorage.protection, .completeUntilFirstUserAuthentication)
                #if targetEnvironment(simulator)
                // Simulator filesystems do not report/emulate iOS data protection.
                // Verify the configured policy here; locked-device behavior needs hardware.
                if let protection = attributes[.protectionKey] as? String {
                    XCTAssertEqual(protection, SignalCrashStorage.protection.rawValue)
                }
                #else
                XCTAssertEqual(attributes[.protectionKey] as? String, SignalCrashStorage.protection.rawValue)
                #endif
                XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
                XCTAssertEqual(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
                XCTAssertEqual(try storage.directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
                XCTAssertTrue(try Data(contentsOf: url).isEmpty)
                installed = true
            }
            capture.prepare()
            XCTAssertTrue(installed)
        }
    }

    func testLegacyAndNewPendingRecoverWithoutOverwritingAndCallbacksCanReenter() throws {
        try withStorage { storage, store, _ in
            try storage.prepareDirectory()
            let oldID = UUID(), newID = UUID()
            _ = try writeRecord(at: XCTUnwrap(storage.legacyPendingURL), captureID: oldID)
            _ = try writeRecord(at: storage.pendingURL, captureID: newID)
            let previous = CrashSignalExceptionHandler.exceptionReceiveClosure
            defer { CrashSignalExceptionHandler.exceptionReceiveClosure = previous }
            var installs = 0
            let capture = SignalCrashCapture(storage: storage, manager: store) { _, _ in installs += 1 }
            var calls = 0
            let thread = Thread.current
            CrashSignalExceptionHandler.exceptionReceiveClosure = { _, _, _ in
                XCTAssertEqual(Thread.current, thread)
                XCTAssertEqual(store.recover(ofType: .signal).count, 2)
                calls += 1
                capture.prepare()
            }
            _ = CrashHandler() // Must not erase the pre-registered observer.
            capture.prepare()
            XCTAssertEqual(installs, 1)
            XCTAssertEqual(calls, 2)
            XCTAssertEqual(store.recover(ofType: .signal).map(\.captureID), [oldID, newID])
            XCTAssertFalse(FileManager.default.fileExists(atPath: storage.legacyPendingURL!.path))
            XCTAssertTrue(try Data(contentsOf: storage.pendingURL).isEmpty)
        }
    }

    func testFailedMigrationRetainsBothPendingFilesAndRetriesBeforeInstall() throws {
        try withStorage { storage, _, root in
            try storage.prepareDirectory()
            let old = try writeRecord(at: XCTUnwrap(storage.legacyPendingURL), captureID: UUID())
            let current = try writeRecord(at: storage.pendingURL, captureID: UUID())
            let destination = root.appendingPathComponent("history")
            // The history directory is empty; remove only this explicit empty directory.
            XCTAssertEqual(rmdir(destination.path), 0)
            let store = CrashManager(directory: destination)
            var installs = 0
            let capture = SignalCrashCapture(storage: storage, manager: store) { _, _ in installs += 1 }
            let previous = CrashSignalExceptionHandler.exceptionReceiveClosure
            defer { CrashSignalExceptionHandler.exceptionReceiveClosure = previous }
            var calls = 0
            CrashSignalExceptionHandler.exceptionReceiveClosure = { _, _, _ in calls += 1 }
            capture.prepare()
            XCTAssertEqual(installs, 0)
            XCTAssertEqual(calls, 0)
            XCTAssertEqual(try Data(contentsOf: XCTUnwrap(storage.legacyPendingURL)), old)
            XCTAssertEqual(try Data(contentsOf: storage.pendingURL), current)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
            capture.prepare()
            XCTAssertEqual(installs, 1)
            XCTAssertEqual(calls, 2)
            XCTAssertEqual(store.recover(ofType: .signal).count, 2)
        }
    }

    func testLateSignalObserverDoesNotReplayRecoveredRecords() throws {
        try withStorage { storage, store, _ in
            _ = try writeRecord(at: XCTUnwrap(storage.legacyPendingURL), captureID: UUID())
            let previous = CrashSignalExceptionHandler.exceptionReceiveClosure
            defer { CrashSignalExceptionHandler.exceptionReceiveClosure = previous }
            CrashSignalExceptionHandler.exceptionReceiveClosure = nil
            let capture = SignalCrashCapture(storage: storage, manager: store) { _, _ in }
            capture.prepare()
            var calls = 0
            CrashSignalExceptionHandler.exceptionReceiveClosure = { _, _, _ in calls += 1 }
            capture.prepare()
            XCTAssertEqual(calls, 0)
            XCTAssertEqual(store.recover(ofType: .signal).count, 1)
        }
    }

    func testInvalidLegacyPendingIsQuarantinedInProtectedStorage() throws {
        try withStorage { storage, store, _ in
            try storage.prepareDirectory()
            let invalidBytes = Data([1, 2, 3])
            try invalidBytes.write(to: XCTUnwrap(storage.legacyPendingURL))
            _ = try writeRecord(at: storage.pendingURL, captureID: UUID())
            var installs = 0
            let capture = SignalCrashCapture(storage: storage, manager: store) { _, _ in installs += 1 }
            capture.prepare()
            XCTAssertEqual(installs, 1)
            XCTAssertEqual(store.recover(ofType: .signal).count, 1)
            XCTAssertFalse(FileManager.default.fileExists(atPath: storage.legacyPendingURL!.path))
            let preserved = try FileManager.default.contentsOfDirectory(at: storage.directory, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix("legacy.bin.invalid-") }
            XCTAssertEqual(preserved.count, 1)
            let url = try XCTUnwrap(preserved.first)
            defer { try? FileManager.default.removeItem(at: url) }
            XCTAssertEqual(try Data(contentsOf: url), invalidBytes)
            XCTAssertEqual(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        }
    }

    func testPendingReadFailureDoesNotInstallOrOverwriteTheOtherRecord() throws {
        try withStorage { storage, store, _ in
            try storage.prepareDirectory()
            let legacy = try XCTUnwrap(storage.legacyPendingURL)
            try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: false)
            let bytes = try writeRecord(at: storage.pendingURL, captureID: UUID())
            var installs = 0
            let capture = SignalCrashCapture(storage: storage, manager: store) { _, _ in installs += 1 }
            capture.prepare()
            XCTAssertEqual(installs, 0)
            XCTAssertEqual(try Data(contentsOf: storage.pendingURL), bytes)
            XCTAssertEqual(rmdir(legacy.path), 0)
            capture.prepare()
            XCTAssertEqual(installs, 1)
            XCTAssertEqual(store.recover(ofType: .signal).count, 1)
        }
    }

    func testInstallationFailureDoesNotReplayAnAlreadyPersistedNotification() throws {
        try withStorage { storage, store, _ in
            _ = try writeRecord(at: XCTUnwrap(storage.legacyPendingURL), captureID: UUID())
            let previous = CrashSignalExceptionHandler.exceptionReceiveClosure
            defer { CrashSignalExceptionHandler.exceptionReceiveClosure = previous }
            var calls = 0
            CrashSignalExceptionHandler.exceptionReceiveClosure = { _, _, _ in calls += 1 }
            var installs = 0
            let capture = SignalCrashCapture(storage: storage, manager: store) { _, _ in
                installs += 1
                if installs == 1 { throw POSIXError(.EIO) }
            }
            capture.prepare()
            XCTAssertEqual(calls, 1)
            capture.prepare()
            XCTAssertEqual(installs, 2)
            XCTAssertEqual(calls, 1)
            XCTAssertEqual(store.recover(ofType: .signal).count, 1)
        }
    }
}
