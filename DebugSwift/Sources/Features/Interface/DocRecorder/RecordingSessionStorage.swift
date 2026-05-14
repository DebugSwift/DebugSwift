//
//  RecordingSessionStorage.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Foundation
import UIKit

@MainActor
final class RecordingSessionStorage {
    static let shared = RecordingSessionStorage()

    private let fileManager = FileManager.default

    private var recordingsDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("DocRecordings", isDirectory: true)
    }

    private var indexFileURL: URL {
        recordingsDirectory.appendingPathComponent("index.json")
    }

    private init() {
        try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save

    func saveRecording(steps: [RecordingSession.Step]) -> SavedRecording? {
        guard !steps.isEmpty else { return nil }

        let recordingID = UUID()
        let recordingDirectory = recordingsDirectory.appendingPathComponent(
            recordingID.uuidString, isDirectory: true
        )

        do {
            try fileManager.createDirectory(at: recordingDirectory, withIntermediateDirectories: true)

            var imageFileNames: [String] = []
            for (index, step) in steps.enumerated() {
                let fileName = String(format: "image-%03d.png", index + 1)
                let fileURL = recordingDirectory.appendingPathComponent(fileName)

                if let pngData = step.annotatedImage.pngData() {
                    try pngData.write(to: fileURL)
                    imageFileNames.append(fileName)
                }
            }

            let savedRecording = SavedRecording(
                id: recordingID,
                date: Date(),
                imageCount: imageFileNames.count,
                imageFileNames: imageFileNames
            )

            var recordings = loadAllRecordings()
            recordings.insert(savedRecording, at: 0)
            try saveIndex(recordings: recordings)

            return savedRecording
        } catch {
            try? fileManager.removeItem(at: recordingDirectory)
            return nil
        }
    }

    // MARK: - Load

    func loadAllRecordings() -> [SavedRecording] {
        guard fileManager.fileExists(atPath: indexFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: indexFileURL)
            return try JSONDecoder().decode([SavedRecording].self, from: data)
        } catch {
            return []
        }
    }

    func loadImages(for recording: SavedRecording) -> [UIImage] {
        let recordingDirectory = recordingsDirectory.appendingPathComponent(
            recording.id.uuidString, isDirectory: true
        )

        var images: [UIImage] = []
        for fileName in recording.imageFileNames {
            let fileURL = recordingDirectory.appendingPathComponent(fileName)
            if let image = UIImage(contentsOfFile: fileURL.path) {
                images.append(image)
            }
        }

        return images
    }

    // MARK: - Delete

    func deleteRecording(_ recording: SavedRecording) {
        let recordingDirectory = recordingsDirectory.appendingPathComponent(
            recording.id.uuidString, isDirectory: true
        )

        do {
            try fileManager.removeItem(at: recordingDirectory)

            var recordings = loadAllRecordings()
            recordings.removeAll { $0.id == recording.id }
            try saveIndex(recordings: recordings)
        } catch {}
    }

    // MARK: - Private Helpers

    private func saveIndex(recordings: [SavedRecording]) throws {
        let data = try JSONEncoder().encode(recordings)
        try data.write(to: indexFileURL)
    }
}
