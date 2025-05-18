//
//  CrashManager.shared.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

class CrashManager: @unchecked Sendable {
    
    private init() {}
    static let shared = CrashManager()
    
    func register() {
        CrashHandler.shared.prepare()
    }

    func save(crash: CrashModel) {
        let filePath = getDocumentsDirectory().appendingPathComponent(crash.type.fileName)

        // Try to load existing crashes from file
        var existingCrashes: [CrashModel] = []
        if let existingData = try? Data(contentsOf: filePath) {
            existingCrashes = (try? JSONDecoder().decode([CrashModel].self, from: existingData)) ?? []
        }

        // Append the new crash
        existingCrashes.append(crash)

        // Save the updated crashes array
        do {
            let jsonData = try JSONEncoder().encode(existingCrashes)
            try jsonData.write(to: filePath)
        } catch {
            Debug.print("Error saving crash data: \(error)")
        }
    }

    func recover(ofType type: CrashType) -> [CrashModel] {
        let filePath = getDocumentsDirectory().appendingPathComponent(type.fileName)

        do {
            let existingData = try Data(contentsOf: filePath)
            return try JSONDecoder().decode([CrashModel].self, from: existingData)
        } catch {
            Debug.print("Error recovering crash data: \(error)")
            return []
        }
    }

    func delete(crash: CrashModel) {
        let filePath = getDocumentsDirectory().appendingPathComponent(crash.type.fileName)

        // Try to load existing crashes from file
        var existingCrashes: [CrashModel] = []
        if let existingData = try? Data(contentsOf: filePath) {
            existingCrashes = (try? JSONDecoder().decode([CrashModel].self, from: existingData)) ?? []
        }

        // Find and remove the specified crash
        existingCrashes.removeAll { $0 == crash }

        // Save the updated crashes array
        do {
            let jsonData = try JSONEncoder().encode(existingCrashes)
            try jsonData.write(to: filePath)
        } catch {
            Debug.print("Error saving crash data: \(error)")
        }
    }

    func deleteAll(ofType type: CrashType) {
        let filePath = getDocumentsDirectory().appendingPathComponent(type.fileName)

        do {
            // Remove the file to delete all crash reports
            try FileManager.default.removeItem(at: filePath)
        } catch {
            Debug.print("Error deleting all crash reports: \(error)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

enum CrashType: String, Codable {
    case nsexception
    case signal

    var fileName: String { "\(rawValue)_crashes.json" }
}
