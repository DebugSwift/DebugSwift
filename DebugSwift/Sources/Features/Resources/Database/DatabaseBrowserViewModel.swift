//
//  DatabaseBrowserViewModel.swift
//  DebugSwift
//
//  ViewModel for Database Browser
//

import Foundation
import UIKit

@MainActor
final class DatabaseBrowserViewModel {
    
    // MARK: - Properties
    
    private let allowedTypes: Set<DatabaseType>?
    private(set) var databases: [DatabaseFile] = []
    private(set) var filteredDatabases: [DatabaseFile] = []
    private var searchText: String = ""

    init(allowedTypes: Set<DatabaseType>? = nil) {
        self.allowedTypes = allowedTypes
    }
    
    // MARK: - Public Methods
    
    func loadDatabaseFiles() {
        let discoveredDatabases = DatabaseFileManager.shared.discoverDatabaseFiles()
        if let allowedTypes {
            databases = discoveredDatabases.filter { allowedTypes.contains($0.type) }
        } else {
            databases = discoveredDatabases
        }
        applyFilter()
    }
    
    func filterDatabases(with searchText: String?) {
        self.searchText = searchText ?? ""
        applyFilter()
    }
    
    // MARK: - Private Methods
    
    private func applyFilter() {
        if searchText.isEmpty {
            filteredDatabases = databases
        } else {
            filteredDatabases = databases.filter { database in
                database.name.localizedCaseInsensitiveContains(searchText) ||
                database.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Database File Manager

final class DatabaseFileManager: @unchecked Sendable {
    static let shared = DatabaseFileManager()
    
    private init() {}
    
    func discoverDatabaseFiles() -> [DatabaseFile] {
        var databaseFiles: [DatabaseFile] = []
        
        // Search in Documents directory
        if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            databaseFiles.append(contentsOf: findDatabaseFiles(in: documentsPath))
        }
        
        // Search in Library directory
        if let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            databaseFiles.append(contentsOf: findDatabaseFiles(in: libraryPath))
        }
        
        // Search in Application Support directory
        if let appSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
            databaseFiles.append(contentsOf: findDatabaseFiles(in: appSupportPath))
        }
        
        // Search in Caches directory
        if let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            databaseFiles.append(contentsOf: findDatabaseFiles(in: cachesPath))
        }
        
        // Search in tmp directory
        let tmpPath = NSTemporaryDirectory()
        databaseFiles.append(contentsOf: findDatabaseFiles(in: tmpPath))
        
        return databaseFiles.sorted { $0.name < $1.name }
    }
    
    private func findDatabaseFiles(in directory: String) -> [DatabaseFile] {
        var files: [DatabaseFile] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: directory) else { return files }
        
        while let fileName = enumerator.nextObject() as? String {
            let fullPath = (directory as NSString).appendingPathComponent(fileName)
            
            // Check if it's a database file
            if let databaseType = DatabaseType.from(fileName: fileName) {
                if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
                   let fileSize = attributes[.size] as? Int64 {
                    let databaseFile = DatabaseFile(
                        name: (fileName as NSString).lastPathComponent,
                        path: fullPath,
                        type: databaseType,
                        size: fileSize
                    )
                    files.append(databaseFile)
                }
            }
        }
        
        return files
    }
}

// MARK: - Models

struct DatabaseFile {
    let name: String
    let path: String
    let type: DatabaseType
    let size: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum DatabaseType: Hashable {
    case sqlite
    case realm
    case coreData
    
    var displayName: String {
        switch self {
        case .sqlite:
            return "SQLite Database"
        case .realm:
            return "Realm Database"
        case .coreData:
            return "Core Data Database"
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .sqlite:
            return UIImage(systemName: "cylinder")
        case .realm:
            return UIImage(systemName: "cylinder.split.1x2")
        case .coreData:
            return UIImage(systemName: "cylinder.fill")
        }
    }
    
    static func from(fileName: String) -> DatabaseType? {
        let lowercased = fileName.lowercased()

        if lowercased.contains("datamodel") &&
            (lowercased.hasSuffix(".sqlite") ||
                lowercased.hasSuffix(".sqlite3") ||
                lowercased.hasSuffix(".db") ||
                lowercased.hasSuffix(".sqlitedb")) {
            return .coreData
        }
        
        if lowercased.hasSuffix(".sqlite") || 
           lowercased.hasSuffix(".sqlite3") ||
           lowercased.hasSuffix(".db") ||
           lowercased.hasSuffix(".sqlitedb") {
            return .sqlite
        } else if lowercased.hasSuffix(".realm") {
            return .realm
        }
        
        return nil
    }
}
