//
//  SQLiteManager.swift
//  DebugSwift
//
//  SQLite database operations manager
//

import Foundation
import SQLite3

final class SQLiteManager: @unchecked Sendable {
    static let shared = SQLiteManager()
    
    private init() {}
    
    // MARK: - Table Operations
    
    func getTables(from path: String) -> [DatabaseTable] {
        var tables: [DatabaseTable] = []
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            Debug.print("Unable to open database at \(path)")
            return tables
        }
        
        defer { sqlite3_close(db) }
        
        let query = """
            SELECT name FROM sqlite_master 
            WHERE type='table' 
            AND name NOT LIKE 'sqlite_%'
            ORDER BY name
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return tables
        }
        
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let namePointer = sqlite3_column_text(statement, 0) {
                let tableName = String(cString: namePointer)
                let columns = getColumns(for: tableName, db: db)
                let rowCount = getRowCount(for: tableName, db: db)
                
                tables.append(DatabaseTable(
                    name: tableName,
                    rowCount: rowCount,
                    columns: columns
                ))
            }
        }
        
        return tables
    }
    
    private func getColumns(for tableName: String, db: OpaquePointer?) -> [DatabaseColumn] {
        var columns: [DatabaseColumn] = []
        let query = "PRAGMA table_info(\(quotedIdentifier(tableName)))"
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return columns
        }
        
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(statement, 1))
            let type = String(cString: sqlite3_column_text(statement, 2))
            let notNull = sqlite3_column_int(statement, 3) != 0
            let isPK = sqlite3_column_int(statement, 5) != 0
            
            columns.append(DatabaseColumn(
                name: name,
                type: type,
                isPrimaryKey: isPK,
                isNullable: !notNull
            ))
        }
        
        return columns
    }
    
    private func getRowCount(for tableName: String, db: OpaquePointer?) -> Int {
        let query = "SELECT COUNT(*) FROM \(quotedIdentifier(tableName))"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        
        return 0
    }
    
    // MARK: - Data Operations
    
    func getTableData(
        from path: String,
        table: String,
        limit: Int = 100,
        offset: Int = 0,
        orderBy: String? = nil,
        ascending: Bool = true
    ) -> (columns: [String], rows: [[Any?]]) {
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return ([], [])
        }
        
        defer { sqlite3_close(db) }
        
        // Get column names
        let columns = getColumnNames(for: table, db: db)
        
        // Build query
        var query = "SELECT * FROM \(quotedIdentifier(table))"
        if let orderBy = orderBy {
            query += " ORDER BY \(quotedIdentifier(orderBy)) \(ascending ? "ASC" : "DESC")"
        }
        query += " LIMIT \(limit) OFFSET \(offset)"
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return (columns, [])
        }
        
        defer { sqlite3_finalize(statement) }
        
        var rows: [[Any?]] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [Any?] = []
            
            for i in 0..<sqlite3_column_count(statement) {
                let type = sqlite3_column_type(statement, i)
                
                switch type {
                case SQLITE_INTEGER:
                    row.append(sqlite3_column_int64(statement, i))
                case SQLITE_FLOAT:
                    row.append(sqlite3_column_double(statement, i))
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(statement, i) {
                        row.append(String(cString: text))
                    } else {
                        row.append(nil)
                    }
                case SQLITE_BLOB:
                    if let blob = sqlite3_column_blob(statement, i) {
                        let size = sqlite3_column_bytes(statement, i)
                        let data = Data(bytes: blob, count: Int(size))
                        row.append(data)
                    } else {
                        row.append(nil)
                    }
                case SQLITE_NULL:
                    row.append(nil)
                default:
                    row.append(nil)
                }
            }
            
            rows.append(row)
        }
        
        return (columns, rows)
    }
    
    private func getColumnNames(for table: String, db: OpaquePointer?) -> [String] {
        var columns: [String] = []
        let query = "SELECT * FROM \(quotedIdentifier(table)) LIMIT 0"
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return columns
        }
        
        defer { sqlite3_finalize(statement) }
        
        let columnCount = sqlite3_column_count(statement)
        for i in 0..<columnCount {
            if let name = sqlite3_column_name(statement, i) {
                columns.append(String(cString: name))
            }
        }
        
        return columns
    }
    
    // MARK: - Query Execution
    
    func executeQuery(path: String, query: String) -> QueryResult {
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            return .error("Unable to open database")
        }
        
        defer { sqlite3_close(db) }
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            return .error(errorMessage)
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Check if it's a SELECT query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmedQuery.hasPrefix("SELECT") {
            var columns: [String] = []
            var rows: [[Any?]] = []
            
            // Get column names
            let columnCount = sqlite3_column_count(statement)
            for i in 0..<columnCount {
                if let name = sqlite3_column_name(statement, i) {
                    columns.append(String(cString: name))
                }
            }
            
            // Get rows
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [Any?] = []
                
                for i in 0..<columnCount {
                    let type = sqlite3_column_type(statement, i)
                    
                    switch type {
                    case SQLITE_INTEGER:
                        row.append(sqlite3_column_int64(statement, i))
                    case SQLITE_FLOAT:
                        row.append(sqlite3_column_double(statement, i))
                    case SQLITE_TEXT:
                        if let text = sqlite3_column_text(statement, i) {
                            row.append(String(cString: text))
                        } else {
                            row.append(nil)
                        }
                    case SQLITE_BLOB:
                        if let blob = sqlite3_column_blob(statement, i) {
                            let size = sqlite3_column_bytes(statement, i)
                            let data = Data(bytes: blob, count: Int(size))
                            row.append(data)
                        } else {
                            row.append(nil)
                        }
                    case SQLITE_NULL:
                        row.append(nil)
                    default:
                        row.append(nil)
                    }
                }
                
                rows.append(row)
            }
            
            return .select(columns: columns, rows: rows)
        } else {
            // Execute non-SELECT query
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE {
                let affectedRows = Int(sqlite3_changes(db))
                return .update(affectedRows: affectedRows)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                return .error(errorMessage)
            }
        }
    }
    
    // MARK: - Insert/Update with Parameters
    
    func executeInsert(path: String, query: String, values: [Any?]) -> QueryResult {
        return executeParameterizedQuery(path: path, query: query, values: values)
    }
    
    func executeUpdate(path: String, query: String, values: [Any?]) -> QueryResult {
        return executeParameterizedQuery(path: path, query: query, values: values)
    }
    
    func executeDelete(path: String, table: String, whereClause: String, values: [Any?]) -> QueryResult {
        let query = "DELETE FROM \(quotedIdentifier(table)) WHERE \(whereClause)"
        return executeParameterizedQuery(path: path, query: query, values: values)
    }

    private func quotedIdentifier(_ identifier: String) -> String {
        "\"\(identifier.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    
    private func executeParameterizedQuery(path: String, query: String, values: [Any?]) -> QueryResult {
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            return .error("Unable to open database")
        }
        
        defer { sqlite3_close(db) }
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            return .error(errorMessage)
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        for (index, value) in values.enumerated() {
            let paramIndex = Int32(index + 1)
            
            if let value = value {
                switch value {
                case let intValue as Int:
                    sqlite3_bind_int64(statement, paramIndex, Int64(intValue))
                case let int64Value as Int64:
                    sqlite3_bind_int64(statement, paramIndex, int64Value)
                case let doubleValue as Double:
                    sqlite3_bind_double(statement, paramIndex, doubleValue)
                case let stringValue as String:
                    sqlite3_bind_text(statement, paramIndex, stringValue, -1, nil)
                case let dataValue as Data:
                    _ = dataValue.withUnsafeBytes { bytes in
                        sqlite3_bind_blob(statement, paramIndex, bytes.baseAddress, Int32(dataValue.count), nil)
                    }
                default:
                    sqlite3_bind_text(statement, paramIndex, "\(value)", -1, nil)
                }
            } else {
                sqlite3_bind_null(statement, paramIndex)
            }
        }
        
        // Execute
        let result = sqlite3_step(statement)
        if result == SQLITE_DONE {
            let affectedRows = Int(sqlite3_changes(db))
            return .update(affectedRows: affectedRows)
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            return .error(errorMessage)
        }
    }
}

// MARK: - Query Result

enum QueryResult {
    case select(columns: [String], rows: [[Any?]])
    case update(affectedRows: Int)
    case error(String)
}
