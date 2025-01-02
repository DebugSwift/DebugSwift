//
//  FileManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class FileManagerTests: XCTestCase {

    var fileManagerHelper: FileManagerHelper!
    let testDirectoryPath = NSTemporaryDirectory() + "TestDirectory"
    let testFilePath = NSTemporaryDirectory() + "TestFile.txt"

    override func setUpWithError() throws {
        try super.setUpWithError()
        fileManagerHelper = FileManagerHelper()
        try FileManager.default.createDirectory(atPath: testDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: testFilePath, contents: nil, attributes: nil)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(atPath: testDirectoryPath)
        fileManagerHelper = nil
        try super.tearDownWithError()
    }

    func testContentsOfDirectoryWithValidPath() throws {
        // Given
        let path = testDirectoryPath

        // When
        let contents = try fileManagerHelper.contentsOfDirectory(atPath: path)

        // Then
        XCTAssertTrue(contents.isEmpty, "The directory should be empty")
    }

    func testContentsOfDirectoryWithInvalidPath() {
        // Given
        let path = "InvalidPath"

        // When / Then
        XCTAssertThrowsError(try fileManagerHelper.contentsOfDirectory(atPath: path), "An error should be thrown for an invalid path")
    }

    func testFileExistsWithValidFile() {
        // Given
        let path = testFilePath
        var isDirectory: ObjCBool = false

        // When
        let exists = fileManagerHelper.fileExists(atPath: path, isDirectory: &isDirectory)

        // Then
        XCTAssertTrue(exists, "The file should exist")
        XCTAssertFalse(isDirectory.boolValue, "The path should not be a directory")
    }

    func testFileExistsWithInvalidFile() {
        // Given
        let path = "InvalidFilePath"
        var isDirectory: ObjCBool = false

        // When
        let exists = fileManagerHelper.fileExists(atPath: path, isDirectory: &isDirectory)

        // Then
        XCTAssertFalse(exists, "The file should not exist")
    }

    func testRemoveItemWithValidPath() throws {
        // Given
        let path = testFilePath

        // When
        try fileManagerHelper.removeItem(atPath: path)

        // Then
        XCTAssertFalse(FileManager.default.fileExists(atPath: path), "The file should be removed")
    }

    func testRemoveItemWithInvalidPath() {
        // Given
        let path = "InvalidPath"

        // When / Then
        XCTAssertThrowsError(try fileManagerHelper.removeItem(atPath: path), "An error should be thrown for an invalid path")
    }

    func testAttributesOfItemWithValidPath() throws {
        // Given
        let path = testFilePath

        // When
        let attributes = try fileManagerHelper.attributesOfItem(atPath: path)

        // Then
        XCTAssertNotNil(attributes, "Attributes should not be nil")
    }

    func testAttributesOfItemWithInvalidPath() {
        // Given
        let path = "InvalidPath"

        // When / Then
        XCTAssertThrowsError(try fileManagerHelper.attributesOfItem(atPath: path), "An error should be thrown for an invalid path")
    }
}
