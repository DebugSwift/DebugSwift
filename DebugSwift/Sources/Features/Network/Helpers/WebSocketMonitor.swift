//
//  WebSocketMonitor.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import Network

@available(iOS 13.0, *)
final class WebSocketMonitor: NSObject, @unchecked Sendable {
    static let shared = WebSocketMonitor()
    
    private var _isEnabled = false
    private var trackedTasks: [URLSessionWebSocketTask: String] = [:]
    private let monitorQueue = DispatchQueue(label: "WebSocketMonitor", qos: .utility)
    
    var isEnabled: Bool {
        get { monitorQueue.sync { _isEnabled } }
        set { monitorQueue.sync { _isEnabled = newValue } }
    }
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Public API
    
    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        // Note: Using manual registration only for now to avoid swizzling complexity
        Debug.print("WebSocket monitoring enabled (manual registration)")
    }
    
    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        // Note: We don't unswizzle methods to avoid potential issues
        Debug.print("WebSocket monitoring disabled")
    }
    
    // MARK: - Connection Tracking
    
    @MainActor
    func trackConnection(_ task: URLSessionWebSocketTask, url: URL, channelName: String? = nil) {
        let connection = WebSocketConnection(url: url, channelName: channelName)
        WebSocketDataSource.shared.addConnection(connection)
        trackedTasks[task] = connection.id
        
        // Start monitoring frames
        monitorFrames(for: task, connectionId: connection.id)
        
        Debug.print("Started tracking WebSocket connection: \(url.absoluteString)")
    }
    
    @MainActor
    private func monitorFrames(for task: URLSessionWebSocketTask, connectionId: String) {
        guard isEnabled else { return }
        
        // Monitor incoming frames
        task.receive { [weak self] result in
            Task { @MainActor in
                self?.handleReceivedFrame(result: result, connectionId: connectionId, task: task)
            }
        }
    }
    

    
    @MainActor
    private func handleReceivedFrame(
        result: Result<URLSessionWebSocketTask.Message, Error>,
        connectionId: String,
        task: URLSessionWebSocketTask
    ) {
        switch result {
        case .success(let message):
            // Update connection status to connected on first successful frame
            if let connection = WebSocketDataSource.shared.getConnection(withId: connectionId),
               connection.status == .connecting {
                WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .connected)
                
                // Notify UI to refresh
                NotificationCenter.default.post(
                    name: NSNotification.Name("reloadWebSocket_DebugSwift"),
                    object: nil
                )
            }
            
            let (frameType, payload) = extractFrameData(from: message)
            let frame = WebSocketFrame(
                direction: .received,
                type: frameType,
                payload: payload,
                connectionId: connectionId
            )
            
            WebSocketDataSource.shared.addFrame(frame)
            
            // Continue monitoring if connection is still active
            if task.state == .running {
                monitorFrames(for: task, connectionId: connectionId)
            }
            
        case .failure(let error):
            WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .error(error))
            Debug.print("WebSocket receive error: \(error.localizedDescription)")
            
            // Notify UI to refresh
            NotificationCenter.default.post(
                name: NSNotification.Name("reloadWebSocket_DebugSwift"),
                object: nil
            )
        }
    }
    
    func extractFrameData(from message: URLSessionWebSocketTask.Message) -> (WebSocketFrameType, Data) {
        switch message {
        case .string(let text):
            return (.text, text.data(using: .utf8) ?? Data())
        case .data(let data):
            return (.binary, data)
        @unknown default:
            return (.binary, Data())
        }
    }
    
    func getConnectionId(for task: URLSessionWebSocketTask) -> String? {
        return trackedTasks[task]
    }
    
    func removeTask(_ task: URLSessionWebSocketTask) {
        trackedTasks.removeValue(forKey: task)
    }
    
    // MARK: - Method Swizzling (Disabled)
    
    // Note: Method swizzling is disabled for WebSocket monitoring to avoid complexity.
    // Using manual registration via DebugSwift.WebSocket.register(task:channelName:) instead.
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("closeWebSocket_DebugSwift"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connectionId = notification.object as? String else { return }
            self?.forceCloseConnection(connectionId: connectionId)
        }
    }
    
    private func forceCloseConnection(connectionId: String) {
        Task { @MainActor in
            // Find and close the WebSocket task
            for (task, taskConnectionId) in trackedTasks where taskConnectionId == connectionId {
                task.cancel(with: .goingAway, reason: "Closed by DebugSwift".data(using: .utf8))
                trackedTasks.removeValue(forKey: task)
                break
            }
        }
    }
}

// MARK: - URLSessionWebSocketTask Extensions (Disabled)

// Note: Swizzled methods are disabled. Using manual registration instead.

 
