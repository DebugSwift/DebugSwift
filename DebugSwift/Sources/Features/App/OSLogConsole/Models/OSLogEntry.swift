//
//  OSLogEntry.swift
//  DebugSwift
//
//  Created by Matheus Gois on 12/05/26.
//

import Foundation

struct OSLogEntry: Identifiable {
    let id = UUID()
    let message: String
    let timestamp: Date
    let subsystem: String?
    let category: String?
    
    init(
        message: String,
        timestamp: Date = Date(),
        subsystem: String? = nil,
        category: String? = nil
    ) {
        self.message = message
        self.timestamp = timestamp
        self.subsystem = subsystem
        self.category = category
    }
    
    var formattedLine: String {
        let sub = subsystem.map { "[\($0)] " } ?? ""
        let cat = category.map { "[\($0)] " } ?? ""
        return "\(DateFormatter.exportFormatter.string(from: timestamp)) \(sub)\(cat)\(message)"
    }
}

private extension DateFormatter {
    static let exportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
