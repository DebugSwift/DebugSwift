//
//  SignalCrashCapture.swift
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

import Foundation
#if canImport(DebugSwiftSignalCapture)
internal import DebugSwiftSignalCapture
#endif

/// Owns startup/recovery. No code in this type is reachable from the C signal handler.
final class SignalCrashCapture: @unchecked Sendable {
    static let shared = SignalCrashCapture(storage: .shared, manager: .shared)

    private let lock = NSLock()
    private var isPrepared = false
    private let storage: SignalCrashStorage
    private let manager: CrashManager
    private let install: (URL, Data) throws -> Void

    init(
        storage: SignalCrashStorage,
        manager: CrashManager,
        install: @escaping (URL, Data) throws -> Void = SignalCrashCapture.installNative
    ) {
        self.storage = storage
        self.manager = manager
        self.install = install
    }

    func prepare() {
        var recovered: [SignalCrashReport] = []
        lock.lock()
        do {
            if !isPrepared {
                try storage.prepareDirectory()
                for url in storage.recoveryURLs {
                    if let report = try Self.recoverPending(
                        at: url, quarantineDirectory: storage.directory,
                        persist: { try manager.persist(crash: $0) }
                    ) {
                        recovered.append(report)
                    }
                }
                try storage.preparePendingFile()
                let metadata = try JSONEncoder().encode(SignalCrashMetadata(details: .builder(name: "")))
                try install(storage.pendingURL, metadata)
                isPrepared = true
            } else {
                Self.prepareCurrentThread()
            }
        } catch {
            // In particular, never truncate a pending report if saving its JSON failed.
            Debug.print("Unable to prepare signal crash capture: \(error)")
        }
        lock.unlock()

        // User callbacks may call prepare() again. Deliver only after releasing the startup lock.
        // Capture one observer for this recovery batch: observer changes/reentrant
        // prepare() calls cannot make another listener receive half of the batch.
        let callback = CrashSignalExceptionHandler.exceptionReceiveClosure
        for report in recovered {
            callback?(report.signal, nil, report.crash.details.name)
        }
    }

    private static func installNative(at url: URL, metadata: Data) throws {
        let result = metadata.withUnsafeBytes { bytes in
            url.path.withCString { path in
                DSSignalCaptureInstall(path, bytes.bindMemory(to: UInt8.self).baseAddress, bytes.count)
            }
        }
        guard result == 0 else { throw POSIXError(POSIXErrorCode(rawValue: result) ?? .EIO) }
    }

    static func prepareCurrentThread() {
        let result = DSSignalCapturePrepareCurrentThread()
        if result != 0 {
            Debug.print("Unable to prepare alternate signal stack: \(result)")
        }
    }

    @discardableResult
    static func recoverPending(
        at url: URL, quarantineDirectory: URL? = nil, persist: (CrashModel) throws -> Void
    ) throws -> SignalCrashReport? {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        }
        // A clean previous run leaves the preopened file empty.
        guard !data.isEmpty else { return nil }
        let report: SignalCrashReport
        do {
            report = try SignalCrashReport(data: data)
        } catch {
            // Preserve incomplete/unknown records for diagnosis without disabling all future capture.
            let invalid = (quarantineDirectory ?? url.deletingLastPathComponent())
                .appendingPathComponent(url.lastPathComponent + ".invalid-\(UUID().uuidString)")
            try FileManager.default.moveItem(at: url, to: invalid)
            if quarantineDirectory != nil {
                // Renaming a legacy file preserves its old attributes; apply the
                // new policy explicitly, including to quarantined diagnostic data.
                try SignalCrashStorage.protectRecord(invalid)
            }
            Debug.print("Preserved invalid signal crash record: \(invalid.lastPathComponent)")
            return nil
        }
        try persist(report.crash)
        try FileManager.default.removeItem(at: url)
        return report
    }
}
