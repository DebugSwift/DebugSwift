//
//  CrashManager.shared.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

class CrashManager: @unchecked Sendable {
    
    private let directory: URL
    private let lock = NSLock()

    init(directory: URL) {
        self.directory = directory
    }

    static let shared = CrashManager(
        directory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    )
    
    func register() {
        CrashHandler.shared.prepare()
    }

    func save(crash: CrashModel) {
        do {
            try persist(crash: crash)
        } catch {
            Debug.print("Error saving crash data: \(error)")
        }
    }

    // Recovery must observe persistence failures before consuming the raw signal record.
    func persist(crash: CrashModel) throws {
        lock.lock()
        defer { lock.unlock() }
        try persistLocked(crash: crash)
    }

    // Fatal NSException paths must not wait for a lock, including their own lock
    // if the exception interrupted an ordinary persist/recover operation. Build
    // the report only after acquiring it; never log through ConsoleOutput here.
    @discardableResult
    func persistException(_ makeCrash: () -> CrashModel) -> Bool {
        guard lock.try() else { return false }
        defer { lock.unlock() }
        do {
            try persistLocked(crash: makeCrash(), reportCorruption: false)
            return true
        } catch {
            return false
        }
    }

    private func persistLocked(crash: CrashModel, reportCorruption: Bool = true) throws {
        let filePath = getDocumentsDirectory().appendingPathComponent(crash.type.fileName)

        var existingCrashes = try loadCrashes(at: filePath, reportCorruption: reportCorruption)

        // The raw record may survive a successful JSON write if recovery was interrupted.
        // A stable capture ID makes that replay harmless without collapsing distinct crashes.
        if let captureID = crash.captureID, existingCrashes.contains(where: { $0.captureID == captureID }) {
            return
        }

        // Append the new crash
        existingCrashes.append(crash)

        // Save the updated crashes array
        let jsonData = try JSONEncoder().encode(existingCrashes)
        try jsonData.write(to: filePath, options: .atomic)
    }

    func recover(ofType type: CrashType) -> [CrashModel] {
        lock.lock()
        defer { lock.unlock() }
        let filePath = getDocumentsDirectory().appendingPathComponent(type.fileName)

        do {
            return try loadCrashes(at: filePath)
        } catch {
            Debug.print("Error recovering crash data: \(error)")
            return []
        }
    }

    func delete(crash: CrashModel) {
        lock.lock()
        defer { lock.unlock() }
        let filePath = getDocumentsDirectory().appendingPathComponent(crash.type.fileName)

        do {
            var existingCrashes = try loadCrashes(at: filePath)
            existingCrashes.removeAll { $0 == crash }
            let jsonData = try JSONEncoder().encode(existingCrashes)
            try jsonData.write(to: filePath, options: .atomic)
        } catch {
            Debug.print("Error saving crash data: \(error)")
        }
    }

    func deleteAll(ofType type: CrashType) {
        lock.lock()
        defer { lock.unlock() }
        let filePath = getDocumentsDirectory().appendingPathComponent(type.fileName)

        do {
            // Remove the file to delete all crash reports
            try FileManager.default.removeItem(at: filePath)
        } catch {
            Debug.print("Error deleting all crash reports: \(error)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        directory
    }

    // Caller holds lock. Only a decoding failure is recoverable corruption; permission,
    // disk and quarantine failures must propagate so pending capture is never consumed.
    private func loadCrashes(at url: URL, reportCorruption: Bool = true) throws -> [CrashModel] {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch CocoaError.fileReadNoSuchFile {
            return []
        }
        do {
            return try JSONDecoder().decode([CrashModel].self, from: data)
        } catch is DecodingError {
            let preserved = url.appendingPathExtension("invalid-\(UUID().uuidString)")
            try FileManager.default.moveItem(at: url, to: preserved)
            if reportCorruption {
                Debug.print("Preserved corrupt crash history at \(preserved.path)")
            }
            return []
        }
    }
}

enum CrashType: String, Codable {
    case nsexception
    case signal

    var fileName: String { "\(rawValue)_crashes.json" }
}
