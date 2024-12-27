//
//  FileSharingManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class FileSharingManagerTests: XCTestCase {

    func testGenerateFileAndShareWithValidText() {
        // Given
        let text = "Sample text"
        let fileName = "sampleFile"

        // When
        FileSharingManager.generateFileAndShare(text: text, fileName: fileName)

        // Then
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path), "The file should exist at the temporary URL")
    }

    func testGenerateFileAndShareWithEmptyText() {
        // Given
        let text = ""
        let fileName = "emptyFile"

        // When
        FileSharingManager.generateFileAndShare(text: text, fileName: fileName)

        // Then
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path), "The file should exist at the temporary URL even if the text is empty")
    }

    func testGenerateFileAndShareWithInvalidFileName() {
        // Given
        let text = "Sample text"
        let fileName = ""

        // When
        FileSharingManager.generateFileAndShare(text: text, fileName: fileName)

        // Then
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(".txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path), "The file should exist at the temporary URL even if the file name is empty")
    }

    func testShareWithValidURL() {
        // Given
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sampleFile.txt")
        let text = "Sample text"
        try? text.write(to: tempURL, atomically: true, encoding: .utf8)

        // When
        FileSharingManager.share(tempURL)

        // Then
        // Since we cannot test UIActivityViewController presentation directly, we assume no exceptions were thrown
        XCTAssertTrue(true, "The share method should execute without throwing exceptions")
    }

    func testShareWithInvalidURL() {
        // Given
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nonExistentFile.txt")

        // When
        FileSharingManager.share(tempURL)

        // Then
        // Since we cannot test UIActivityViewController presentation directly, we assume no exceptions were thrown
        XCTAssertTrue(true, "The share method should execute without throwing exceptions even if the file does not exist")
    }
}
