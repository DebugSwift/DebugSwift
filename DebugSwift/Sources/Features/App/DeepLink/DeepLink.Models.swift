//
//  DeepLink.Models.swift
//  DebugSwift
//
//  Created by DebugSwift on 13/02/26.
//

import Foundation

enum DeepLinkType {
    case urlScheme
    case universalLink
    
    var displayName: String {
        switch self {
        case .urlScheme:
            return "URL Scheme"
        case .universalLink:
            return "Universal Link"
        }
    }
    
    var icon: String {
        switch self {
        case .urlScheme:
            return "link.circle.fill"
        case .universalLink:
            return "globe"
        }
    }
}

enum DeepLinkStatus {
    case success
    case failed(String)
    case invalid(String)
    
    var displayName: String {
        switch self {
        case .success:
            return "Success"
        case .failed:
            return "Failed"
        case .invalid:
            return "Invalid"
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "✅"
        case .failed:
            return "❌"
        case .invalid:
            return "⚠️"
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .failed(let message), .invalid(let message):
            return message
        }
    }
}

struct DeepLinkEntry: Codable {
    let id: UUID
    let urlString: String
    let timestamp: Date
    let type: String
    let statusRawValue: String
    let errorMessage: String?
    
    init(url: URL, type: DeepLinkType, status: DeepLinkStatus) {
        self.id = UUID()
        self.urlString = url.absoluteString
        self.timestamp = Date()
        self.type = type.displayName
        self.statusRawValue = status.displayName
        self.errorMessage = status.errorMessage
    }
    
    var url: URL? {
        URL(string: urlString)
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
    
    var statusIcon: String {
        switch statusRawValue {
        case "Success":
            return "✅"
        case "Failed":
            return "❌"
        case "Invalid":
            return "⚠️"
        default:
            return "❓"
        }
    }
}
