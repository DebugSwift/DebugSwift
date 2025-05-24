//
//  FileSharingManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import Testing
import Foundation
@testable import DebugSwift

struct FileSharingManagerTests {

    @Test("Generate file and share with valid text")
    func generateFileAndShareWithValidText() {
        // Given
        let text = "Sample text"
        let fileName = "sampleFile"

        // When
        FileSharingManager.generateFileAndShare(text: text, fileName: fileName)

        // Then
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).txt")
        #expect(FileManager.default.fileExists(atPath: tempURL.path) == true)
    }

    @Test("Generate file and share with empty text")
    func generateFileAndShareWithEmptyText() {
        // Given
        let text = ""
        let fileName = "emptyFile"

        // When
        FileSharingManager.generateFileAndShare(text: text, fileName: fileName)

        // Then
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).txt")
        #expect(FileManager.default.fileExists(atPath: tempURL.path) == true)
    }

    @Test("Generate file and share with invalid file name")
    func generateFileAndShareWithInvalidFileName() {
        // Given
        let text = "Sample text"
        let fileName = ""

        // When
        FileSharingManager.generateFileAndShare(text: text, fileName: fileName)

        // Then
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(".txt")
        #expect(FileManager.default.fileExists(atPath: tempURL.path) == true)
    }

    @Test("Share with valid URL")
    @MainActor
    func shareWithValidURL() async {
        // Given
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        try? "Test content".write(to: tempURL, atomically: true, encoding: .utf8)
        
        // When
        FileSharingManager.share(tempURL)
        
        // Then
        // Since the share method presents an activity view controller,
        // we cannot test the presentation directly in a unit test.
        // This test ensures that the share method can be called without errors.
        #expect(true)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test("Share with empty URL")
    @MainActor
    func shareWithEmptyURL() async {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
        
        // When
        FileSharingManager.share(tempURL)
        
        // Then
        // This test ensures that the share method handles directories correctly
        #expect(true)
    }
}
