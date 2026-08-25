//
//  RealmManagerTests.swift
//  ExampleTests
//
//  Tests for RealmManager header parsing and metadata surfacing.
//

import XCTest
@testable import DebugSwift

final class RealmManagerTests: XCTestCase {

    private var temporaryDirectory: URL!
    private var manager: RealmManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RealmManagerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        manager = RealmManager.shared
    }

    override func tearDownWithError() throws {
        if let directory = temporaryDirectory {
            try? FileManager.default.removeItem(at: directory)
        }
        temporaryDirectory = nil
        manager = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    private func writeRealmFile(named fileName: String, fileFormat: (UInt8, UInt8) = (24, 24)) throws -> URL {
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        var data = Data(count: 128 * 1024)

        // Layout: m_top_ref[2] (16) | m_mnemonic[4] (offset 16) | m_file_format[2] (offset 20) | m_reserved (offset 22) | m_flags (offset 23)
        // Top ref slot 0: 0xFFFFFFFFFFFFFFFF (uninitialized)
        data.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress else { return }
            base.storeBytes(of: UInt64(0xFFFFFFFFFFFFFFFF), toByteOffset: 0, as: UInt64.self)
            base.storeBytes(of: UInt64(0), toByteOffset: 8, as: UInt64.self)
        }

        // Mnemonic "T-DB" at offset 16
        data[16] = 0x54 // T
        data[17] = 0x2D // -
        data[18] = 0x44 // D
        data[19] = 0x42 // B

        // File format version at offset 20-21
        data[20] = fileFormat.0
        data[21] = fileFormat.1

        // Reserved byte at offset 22
        data[22] = 0x00

        // Flags byte at offset 23
        data[23] = 0x00

        try data.write(to: fileURL)
        return fileURL
    }

    private func writeNonRealmFile(named fileName: String) throws -> URL {
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        try Data(repeating: 0x00, count: 1024).write(to: fileURL)
        return fileURL
    }

    // MARK: - getTables

    func testGetTablesReturnsSingleTableForValidRealmFile() throws {
        let realmURL = try writeRealmFile(named: "test.realm")
        let tables = manager.getTables(from: realmURL.path)

        XCTAssertEqual(tables.count, 1, "Valid Realm file should surface a single informational table")
        let table = try XCTUnwrap(tables.first)
        XCTAssertEqual(table.rowCount, 1)
        XCTAssertEqual(table.columns.count, 2)
        XCTAssertEqual(table.columns.first?.name, "Property")
        XCTAssertEqual(table.columns.last?.name, "Value")
        XCTAssertTrue(table.name.hasPrefix("Realm ("))
    }

    func testGetTablesReturnsEmptyForNonRealmFile() throws {
        let nonRealmURL = try writeNonRealmFile(named: "fake.realm")
        let tables = manager.getTables(from: nonRealmURL.path)
        XCTAssertTrue(tables.isEmpty, "Files without the T-DB mnemonic should return no tables")
    }

    func testGetTablesReturnsEmptyForMissingFile() {
        let tables = manager.getTables(from: "/nonexistent/path/test.realm")
        XCTAssertTrue(tables.isEmpty, "Missing files should return no tables")
    }

    func testGetTablesParsesFileFormatVersion() throws {
        let realmURL = try writeRealmFile(named: "versioned.realm", fileFormat: (24, 24))
        let tables = manager.getTables(from: realmURL.path)
        let table = try XCTUnwrap(tables.first)
        XCTAssertTrue(table.name.contains("24"), "Table name should contain the file format version, got: \(table.name)")
    }

    // MARK: - getTableData

    func testGetTableDataReturnsMetadataRowsForValidRealmFile() throws {
        let realmURL = try writeRealmFile(named: "data.realm")
        let result = manager.getTableData(from: realmURL.path, table: "Realm (24)")

        XCTAssertEqual(result.columns, ["Property", "Value"])
        XCTAssertFalse(result.rows.isEmpty, "Should return metadata rows for a valid Realm file")

        // Verify the mnemonic row
        let mnemonicRow = result.rows.first { $0.first as? String == "Mnemonic" }
        XCTAssertEqual(mnemonicRow?.last as? String, "T-DB")

        // Verify the file format row
        let formatRow = result.rows.first { $0.first as? String == "File format" }
        XCTAssertEqual(formatRow?.last as? String, "24")

        // Verify the note row mentions RealmSwift
        let noteRow = result.rows.first { $0.first as? String == "Note" }
        XCTAssertNotNil(noteRow, "A note row should be present")
        XCTAssertTrue((noteRow?.last as? String ?? "").contains("RealmSwift"))
    }

    func testGetTableDataReturnsEmptyForNonRealmFile() throws {
        let nonRealmURL = try writeNonRealmFile(named: "fake2.realm")
        let result = manager.getTableData(from: nonRealmURL.path, table: "test")
        XCTAssertTrue(result.columns.isEmpty)
        XCTAssertTrue(result.rows.isEmpty)
    }

    func testGetTableDataReturnsEmptyForMissingFile() {
        let result = manager.getTableData(from: "/nonexistent/path/test.realm", table: "test")
        XCTAssertTrue(result.columns.isEmpty)
        XCTAssertTrue(result.rows.isEmpty)
    }
}
