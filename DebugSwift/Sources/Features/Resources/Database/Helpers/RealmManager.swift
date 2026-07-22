//
//  RealmManager.swift
//  DebugSwift
//
//  Realm database operations manager.
//
//  The Realm binary format (realm-core) has no stable public specification and
//  evolves across file-format versions, so this manager does not parse object
//  schemas or row data. It reads the 24-byte file header defined in
//  realm-core's SlabAlloc::Header to validate the file and surface its
//  file-format version to the database browser, giving the user honest
//  feedback instead of silently returning empty results that make the browser
//  look broken. Full introspection requires linking RealmSwift, which is an
//  application-side dependency and out of scope for this drop-in toolkit.

import Foundation

final class RealmManager: @unchecked Sendable {
    static let shared = RealmManager()

    private init() {}

    // MARK: - Table Operations

    func getTables(from path: String) -> [DatabaseTable] {
        guard let header = readHeader(at: path) else {
            Debug.print("Unable to read Realm database at \(path)")
            return []
        }

        // Surface the file itself as a single informational "table" so the
        // browser lists Realm files and can drill into the metadata below.
        return [
            DatabaseTable(
                name: header.tableName,
                rowCount: 1,
                columns: [
                    DatabaseColumn(name: "Property", type: "string", isPrimaryKey: false, isNullable: false),
                    DatabaseColumn(name: "Value", type: "string", isPrimaryKey: false, isNullable: false)
                ]
            )
        ]
    }

    // MARK: - Data Operations

    func getTableData(
        from path: String,
        table: String,
        limit: Int = 100,
        offset: Int = 0
    ) -> (columns: [String], rows: [[Any?]]) {
        guard let header = readHeader(at: path) else {
            return ([], [])
        }

        return (
            ["Property", "Value"],
            [
                ["File", table],
                ["Mnemonic", header.mnemonic],
                ["File format", "\(header.fileFormat)"],
                ["Reserved byte", String(format: "0x%02X", header.reserved)],
                ["Flags byte", String(format: "0x%02X", header.flags)],
                ["Top ref (slot 0)", String(format: "0x%016llX", header.topRef0)],
                ["Top ref (slot 1)", String(format: "0x%016llX", header.topRef1)],
                [
                    "Note",
                    "Object schemas and row data require RealmSwift; the Realm binary layout is not parsed in-tree."
                ]
            ]
        )
    }

    // MARK: - Header Parsing

    /// The 24-byte Realm file header defined by `SlabAlloc::Header` in realm-core.
    private struct RealmHeader {
        let topRef0: UInt64
        let topRef1: UInt64
        let mnemonic: String
        let fileFormat: Int
        let reserved: UInt8
        let flags: UInt8
        let tableName: String
    }

    private func readHeader(at path: String) -> RealmHeader? {
        guard let handle = FileHandle(forReadingAtPath: path) else {
            return nil
        }
        defer { handle.closeFile() }

        let headerData = handle.readData(ofLength: 24)
        guard headerData.count == 24 else {
            return nil
        }

        return headerData.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> RealmHeader? in
            guard let base = raw.baseAddress else { return nil }

            // Layout: m_top_ref[2] (16) | m_mnemonic[4] (offset 16) | m_file_format[2] (offset 20) | m_reserved (offset 22) | m_flags (offset 23)
            let mnemonic = String(bytes: headerData[16..<20], encoding: .ascii) ?? ""

            // Realm files carry the "T-DB" mnemonic in the header.
            guard mnemonic == "T-DB" else { return nil }

            // `load(fromByteOffset:as:)` honors the type's alignment and is
            // the safe way to read unaligned integers from a raw buffer.
            let topRef0 = base.load(fromByteOffset: 0, as: UInt64.self)
            let topRef1 = base.load(fromByteOffset: 8, as: UInt64.self)

            let fileFormatHigh = Int(headerData[20])
            let fileFormatLow = Int(headerData[21])
            let fileFormat = fileFormatHigh == 0 ? fileFormatLow : fileFormatHigh

            let reserved = headerData[22]
            let flags = headerData[23]

            let tableName = "Realm (\(fileFormat))"

            return RealmHeader(
                topRef0: topRef0,
                topRef1: topRef1,
                mnemonic: mnemonic,
                fileFormat: fileFormat,
                reserved: reserved,
                flags: flags,
                tableName: tableName
            )
        }
    }
}
