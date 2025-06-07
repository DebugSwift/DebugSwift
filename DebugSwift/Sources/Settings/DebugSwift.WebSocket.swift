//
//  DebugSwift.WebSocket.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation

extension DebugSwift {
    public enum WebSocket {
        
        /// Register a WebSocket connection for monitoring
        /// Call this method after creating your URLSessionWebSocketTask but before calling resume()
        /// 
        /// Example usage:
        /// ```swift
        /// let task = URLSession.shared.webSocketTask(with: url)
        /// DebugSwift.WebSocket.register(task: task, channelName: "Chat Channel")
        /// task.resume()
        /// ```
        /// 
        /// - Parameters:
        ///   - task: The URLSessionWebSocketTask to monitor
        ///   - channelName: Optional friendly name for the connection (e.g., "Chat", "Live Updates")
        @available(iOS 13.0, *)
        @MainActor
        public static func register(task: URLSessionWebSocketTask, channelName: String? = nil) {
            guard let url = task.originalRequest?.url else {
                Debug.print("Warning: Cannot register WebSocket task without URL")
                return
            }
            
            WebSocketMonitor.shared.trackConnection(task, url: url, channelName: channelName)
        }
        
        /// Enable WebSocket monitoring manually
        /// This is automatically called when DebugSwift is set up, but you can call it manually if needed
        @available(iOS 13.0, *)
        public static func enableMonitoring() {
            WebSocketMonitor.shared.enable()
        }
        
        /// Disable WebSocket monitoring
        /// This will stop intercepting new WebSocket traffic but preserve existing data
        @available(iOS 13.0, *)
        public static func disableMonitoring() {
            WebSocketMonitor.shared.disable()
        }
        
        /// Check if WebSocket monitoring is currently enabled
        @available(iOS 13.0, *)
        public static var isMonitoringEnabled: Bool {
            WebSocketMonitor.shared.isEnabled
        }
        
        /// Get the current number of active WebSocket connections
        @MainActor
        public static var activeConnectionCount: Int {
            WebSocketDataSource.shared.getActiveConnections().count
        }
        
        /// Get the total number of unread frames across all connections
        @MainActor
        public static var totalUnreadFrames: Int {
            WebSocketDataSource.shared.getTotalUnreadFrames()
        }
        
        /// Clear all WebSocket connections and frames
        /// This removes all data from the WebSocket inspector
        @MainActor
        public static func clearAllData() {
            WebSocketDataSource.shared.removeAllConnections()
        }
        
        /// Clear frames for a specific connection by URL
        /// - Parameter url: The WebSocket URL to clear frames for
        @MainActor
        public static func clearFrames(for url: URL) {
            let connections = WebSocketDataSource.shared.getAllConnections()
            if let connection = connections.first(where: { $0.url == url }) {
                WebSocketDataSource.shared.clearFrames(for: connection.id)
            }
        }
        
        /// Log a sent frame for monitoring
        /// Call this method whenever you send a frame through your WebSocket connection
        /// 
        /// Example usage:
        /// ```swift
        /// let message = URLSessionWebSocketTask.Message.string("Hello")
        /// task.send(message) { error in
        ///     // Handle error
        /// }
        /// DebugSwift.WebSocket.logSentFrame(task: task, message: message)
        /// ```
        /// 
        /// - Parameters:
        ///   - task: The URLSessionWebSocketTask that sent the frame
        ///   - message: The message that was sent
        @available(iOS 13.0, *)
        @MainActor
        public static func logSentFrame(task: URLSessionWebSocketTask, message: URLSessionWebSocketTask.Message) {
            guard let connectionId = WebSocketMonitor.shared.getConnectionId(for: task) else {
                Debug.print("Warning: Cannot log sent frame - task not registered with DebugSwift")
                return
            }
            
            let (frameType, payload) = WebSocketMonitor.shared.extractFrameData(from: message)
            let frame = WebSocketFrame(
                direction: .sent,
                type: frameType,
                payload: payload,
                connectionId: connectionId
            )
            
            WebSocketDataSource.shared.addFrame(frame)
        }
        
        /// Log a sent text frame for monitoring
        /// Convenience method for sending text messages
        /// 
        /// - Parameters:
        ///   - task: The URLSessionWebSocketTask that sent the frame
        ///   - text: The text that was sent
        @available(iOS 13.0, *)
        @MainActor
        public static func logSentFrame(task: URLSessionWebSocketTask, text: String) {
            logSentFrame(task: task, message: .string(text))
        }
        
        /// Log a sent binary frame for monitoring
        /// Convenience method for sending binary data
        /// 
        /// - Parameters:
        ///   - task: The URLSessionWebSocketTask that sent the frame
        ///   - data: The binary data that was sent
        @available(iOS 13.0, *)
        @MainActor
        public static func logSentFrame(task: URLSessionWebSocketTask, data: Data) {
            logSentFrame(task: task, message: .data(data))
        }
    }
} 