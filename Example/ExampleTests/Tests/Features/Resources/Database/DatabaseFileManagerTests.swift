//
//  DatabaseFileManagerTests.swift
//  ExampleTests
//
//  Tests for database file discovery de-duplication via indirect integration testing
//

import XCTest
@testable import DebugSwift

final class DatabaseFileManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        cleanupTestFiles()
    }

    override func tearDown() {
        cleanupTestFiles()
        super.tearDown()
    }

    func testDiscoverDatabaseFilesDeduplicatesEquivalentPaths() {
        let manager = DatabaseFileManager.shared
        let fileManager = FileManager.default
        
        // Search in standard directories used by DatabaseFileManager
        guard let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first,
              let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            XCTFail("Failed to get standard directories")
            return
        }
        
        let dbName = "TestDeduplicate.db"
        let realDBPath = (cachesPath as NSString).appendingPathComponent(dbName)
        let symlinkPath = (documentsPath as NSString).appendingPathComponent("SymlinkDeduplicate.db")
        
        // Create a real database file in Caches
        fileManager.createFile(atPath: realDBPath, contents: Data("dummy db".utf8), attributes: nil)
        
        // Create a symbolic link in Documents pointing to the Caches DB
        // Both directories are searched by DatabaseFileManager.discoverDatabaseFiles()
        do {
            try fileManager.createSymbolicLink(atPath: symlinkPath, withDestinationPath: realDBPath)
        } catch {
            XCTFail("Failed to create symlink: \(error)")
            return
        }
        
        // Verify both exist on disk
        XCTAssertTrue(fileManager.fileExists(atPath: realDBPath))
        XCTAssertTrue(fileManager.fileExists(atPath: symlinkPath))
        
        // Execute discovery - this internally calls the private deduplicateDatabaseFiles method
        let discoveredFiles = manager.discoverDatabaseFiles()
        
        // Verify deduplication results
        let testDBs = discoveredFiles.filter { $0.name == dbName || $0.name == "SymlinkDeduplicate.db" }
        
        // If deduplication works correctly (resolving symlinks to original paths),
        // only one entry should remain because both paths point to the same file.
        XCTAssertEqual(testDBs.count, 1, "Discovered files should be deduplicated")
        
        // Either the symlink or the real path might be kept depending on search order
        let remainingPath = testDBs.first?.path
        XCTAssertTrue(remainingPath == realDBPath || remainingPath == symlinkPath, 
                      "The remaining file path should be either the real path or the symlink path")
    }

    private func cleanupTestFiles() {
        let fileManager = FileManager.default
        let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        
        if let cachesPath = cachesPath {
            let realDBPath = (cachesPath as NSString).appendingPathComponent("TestDeduplicate.db")
            try? fileManager.removeItem(atPath: realDBPath)
        }
        
        if let documentsPath = documentsPath {
            let symlinkPath = (documentsPath as NSString).appendingPathComponent("SymlinkDeduplicate.db")
            try? fileManager.removeItem(atPath: symlinkPath)
        }
    }
}
