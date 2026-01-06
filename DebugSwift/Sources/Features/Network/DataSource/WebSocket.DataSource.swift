//
//  WebSocket.DataSource.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation

@MainActor
public final class WebSocketDataSource: ObservableObject {
    public static let shared = WebSocketDataSource()

    @Published private var connections: [WebSocketConnection] = []
    private let queue = DispatchQueue(label: "WebSocketDataSource", qos: .utility)

    private init() {}
    
    // MARK: - Connection Management

    public func addConnection(_ connection: WebSocketConnection) {
        connections.append(connection)
        postUpdateNotification()
    }

    public func removeConnection(withId id: String) {
        connections.removeAll { $0.id == id }
        postUpdateNotification()
    }

    public func getConnection(withId id: String) -> WebSocketConnection? {
        return connections.first { $0.id == id }
    }

    public func getAllConnections() -> [WebSocketConnection] {
        return connections
    }

    public func getActiveConnections() -> [WebSocketConnection] {
        return connections.filter { $0.isActive }
    }

    public func getConnectionsSortedByActivity() -> [WebSocketConnection] {
        return connections.sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    // MARK: - Frame Management

    public func addFrame(_ frame: WebSocketFrame) {
        guard let connection = getConnection(withId: frame.connectionId) else {
            return
        }

        connection.addFrame(frame)
        postUpdateNotification()
    }

    public func clearFrames(for connectionId: String) {
        guard let connection = getConnection(withId: connectionId) else {
            return
        }

        connection.clearFrames()
        postUpdateNotification()
    }

    public func clearAllFrames() {
        connections.forEach { $0.clearFrames() }
        postUpdateNotification()
    }

    public func markConnectionAsRead(_ connectionId: String) {
        guard let connection = getConnection(withId: connectionId) else {
            return
        }

        connection.markAsRead()
        postUpdateNotification()
    }

    // MARK: - Connection Status Updates

    public func updateConnectionStatus(_ connectionId: String, status: WebSocketConnectionStatus) {
        guard let connection = getConnection(withId: connectionId) else {
            return
        }

        connection.updateStatus(status)
        postUpdateNotification()
    }
    
    // MARK: - Search and Filtering
    
    func searchFrames(in connectionId: String, query: String) -> [WebSocketFrame] {
        guard let connection = getConnection(withId: connectionId),
              !query.isEmpty else {
            return getConnection(withId: connectionId)?.frames ?? []
        }
        
        let lowercaseQuery = query.lowercased()
        
        return connection.frames.filter { frame in
            // Search in payload text
            if let payloadString = frame.payloadString {
                return payloadString.lowercased().contains(lowercaseQuery)
            }
            
            // Search in pretty printed JSON
            if let jsonString = frame.prettyPrintedJSON {
                return jsonString.lowercased().contains(lowercaseQuery)
            }
            
            return false
        }
    }
    
    func filterFrames(in connectionId: String, direction: WebSocketFrameDirection?, minSize: Int = 0) -> [WebSocketFrame] {
        guard let connection = getConnection(withId: connectionId) else {
            return []
        }
        
        return connection.frames.filter { frame in
            if let direction = direction, frame.direction != direction {
                return false
            }
            
            if frame.payloadSize < minSize {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Statistics
    
    func getTotalFrameCount(for connectionId: String) -> Int {
        return getConnection(withId: connectionId)?.frames.count ?? 0
    }
    
    func getUnreadFrameCount(for connectionId: String) -> Int {
        return getConnection(withId: connectionId)?.unreadFrameCount ?? 0
    }
    
    func getTotalUnreadFrames() -> Int {
        return connections.reduce(0) { $0 + $1.unreadFrameCount }
    }
    
    // MARK: - Cleanup
    
    func removeAllConnections() {
        connections.removeAll()
        postUpdateNotification()
    }
    
    func forceCloseConnection(_ connectionId: String) {
        guard let connection = getConnection(withId: connectionId) else {
            return
        }
        
        connection.updateStatus(.closed)
        postUpdateNotification()
        
        // Notify the WebSocket monitor to actually close the connection
        NotificationCenter.default.post(
            name: NSNotification.Name("closeWebSocket_DebugSwift"),
            object: connectionId
        )
    }
    
    // MARK: - Private Methods
    
    private func postUpdateNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("reloadWebSocket_DebugSwift"),
                object: nil
            )
        }
    }
} 