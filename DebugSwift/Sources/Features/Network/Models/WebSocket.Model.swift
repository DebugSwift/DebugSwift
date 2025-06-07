//
//  WebSocket.Model.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import UIKit

enum WebSocketFrameDirection {
    case sent
    case received
}

enum WebSocketFrameType {
    case text
    case binary
    case ping
    case pong
    case close
    case continuation
}

enum WebSocketConnectionStatus: Equatable {
    case connecting
    case connected
    case reconnecting
    case closed
    case error(Error)
    
    static func == (lhs: WebSocketConnectionStatus, rhs: WebSocketConnectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.connecting, .connecting),
             (.connected, .connected),
             (.reconnecting, .reconnecting),
             (.closed, .closed):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        default:
            return false
        }
    }
    
    var displayString: String {
        switch self {
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting"
        case .closed:
            return "Closed"
        case .error:
            return "Error"
        }
    }
    
    var color: UIColor {
        switch self {
        case .connecting, .reconnecting:
            return .systemOrange
        case .connected:
            return .systemGreen
        case .closed:
            return .systemGray
        case .error:
            return .systemRed
        }
    }
}

final class WebSocketFrame: NSObject {
    let id = UUID().uuidString
    let timestamp: Date
    let direction: WebSocketFrameDirection
    let type: WebSocketFrameType
    let payload: Data
    let payloadSize: Int
    let connectionId: String
    
    var payloadString: String? {
        // Try to convert any payload to string if it's valid UTF-8
        return String(data: payload, encoding: .utf8)
    }
    
    var isJSON: Bool {
        guard let payloadString = payloadString else { return false }
        let trimmed = payloadString.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) || 
               (trimmed.hasPrefix("[") && trimmed.hasSuffix("]"))
    }
    
    var prettyPrintedJSON: String? {
        guard let payloadString = payloadString,
              let jsonData = payloadString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }
    
    var effectiveType: WebSocketFrameType {
        // If marked as binary but is actually valid text, treat as text
        if type == .binary && payloadString != nil {
            return .text
        }
        return type
    }
    
    var payloadPreview: String {
        if let jsonString = prettyPrintedJSON {
            return String(jsonString.prefix(50))
        } else if let textString = payloadString {
            return String(textString.prefix(50))
        } else {
            return "<Binary Data: \(payloadSize) bytes>"
        }
    }
    
    var hexDump: String {
        return payload.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    
    init(direction: WebSocketFrameDirection, type: WebSocketFrameType, payload: Data, connectionId: String) {
        self.timestamp = Date()
        self.direction = direction
        self.type = type
        self.payload = payload
        self.payloadSize = payload.count
        self.connectionId = connectionId
        super.init()
    }
}

final class WebSocketConnection: NSObject {
    let id = UUID().uuidString
    let url: URL
    let channelName: String?
    var status: WebSocketConnectionStatus = .connecting
    var frames: [WebSocketFrame] = []
    let createdAt: Date
    var lastActivityAt: Date
    var unreadFrameCount: Int = 0
    
    private let maxFrames = 1000 // Prevent unbounded memory usage
    
    var displayName: String {
        return channelName ?? url.absoluteString
    }
    
    var isActive: Bool {
        switch status {
        case .connected, .connecting, .reconnecting:
            return true
        case .closed, .error:
            return false
        }
    }
    
    init(url: URL, channelName: String? = nil) {
        self.url = url
        self.channelName = channelName
        self.createdAt = Date()
        self.lastActivityAt = Date()
        super.init()
    }
    
    func addFrame(_ frame: WebSocketFrame) {
        frames.append(frame)
        lastActivityAt = Date()
        unreadFrameCount += 1
        
        // Prune old frames to prevent memory issues
        if frames.count > maxFrames {
            frames.removeFirst(frames.count - maxFrames)
        }
    }
    
    func clearFrames() {
        frames.removeAll()
        unreadFrameCount = 0
    }
    
    func markAsRead() {
        unreadFrameCount = 0
    }
    
    func updateStatus(_ status: WebSocketConnectionStatus) {
        self.status = status
        lastActivityAt = Date()
    }
} 