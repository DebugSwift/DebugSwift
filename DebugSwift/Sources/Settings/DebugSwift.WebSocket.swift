//
//  DebugSwift.WebSocket.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation

extension DebugSwift {
    public enum WebSocket {
        /// Enable WebSocket monitoring manually
        /// 
        /// WebSocket monitoring uses automatic method swizzling to detect connections and frames.
        /// This is automatically called when DebugSwift is set up, but you can call it manually if needed.
        /// 
        /// - Note: With method swizzling enabled, all WebSocket traffic is automatically monitored
        public static func enableMonitoring() {
            WebSocketMonitor.shared.enable()
        }
        
        /// Disable WebSocket monitoring
        /// 
        /// This will stop intercepting new WebSocket traffic but preserve existing data.
        /// Method swizzling will be disabled until re-enabled.
        public static func disableMonitoring() {
            WebSocketMonitor.shared.disable()
        }
        
        /// Check if WebSocket monitoring is currently enabled
        /// 
        /// When enabled, method swizzling automatically captures all WebSocket connections and frames
        public static var isMonitoringEnabled: Bool {
            WebSocketMonitor.shared.isEnabled
        }
        
        // MARK: - Manual Registration (Optional)
        
        /// Register a WebSocket task with a custom channel name
        /// 
        /// This is optional with automatic method swizzling but useful for organizing connections
        /// by custom channel names in the inspector.
        /// 
        /// - Parameters:
        ///   - task: The WebSocket task to register
        ///   - channelName: Custom channel name for organization (optional)
        @MainActor
        public static func register(task: URLSessionWebSocketTask, channelName: String? = nil) {
            WebSocketMonitor.shared.register(task: task, channelName: channelName)
        }
        
        // MARK: - Manual Frame Logging (Optional)
        
        /// Manually log a sent text frame
        /// 
        /// This is optional with automatic method swizzling but can be used for additional
        /// metadata or custom logging scenarios.
        /// 
        /// - Parameters:
        ///   - task: The WebSocket task
        ///   - text: The text content that was sent
        @MainActor
        public static func logSentFrame(task: URLSessionWebSocketTask, text: String) {
            WebSocketMonitor.shared.logSentFrame(task: task, message: .string(text))
        }
        
        /// Manually log a sent data frame
        /// 
        /// - Parameters:
        ///   - task: The WebSocket task
        ///   - data: The data content that was sent
        @MainActor
        public static func logSentFrame(task: URLSessionWebSocketTask, data: Data) {
            WebSocketMonitor.shared.logSentFrame(task: task, message: .data(data))
        }
        
        /// Manually log a sent WebSocket message
        /// 
        /// - Parameters:
        ///   - task: The WebSocket task
        ///   - message: The WebSocket message that was sent
        @MainActor
        public static func logSentFrame(task: URLSessionWebSocketTask, message: URLSessionWebSocketTask.Message) {
            WebSocketMonitor.shared.logSentFrame(task: task, message: message)
        }
        
        // MARK: - Statistics & Data Management
        
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
            guard let connection = WebSocketDataSource.shared.getAllConnections().first(where: { $0.url == url }) else {
                return
            }
            WebSocketDataSource.shared.clearFrames(for: connection.id)
        }
        
        /// Clear frames for a specific connection by task
        /// - Parameter task: The WebSocket task to clear frames for
        @MainActor
        public static func clearFrames(for task: URLSessionWebSocketTask) {
            guard let url = task.currentRequest?.url else { return }
            clearFrames(for: url)
        }
        
        // MARK: - Connection Management
        
        /// Get all active WebSocket connections
        @MainActor
        public static func getActiveConnections() -> [WebSocketConnection] {
            WebSocketDataSource.shared.getActiveConnections()
        }
        
        /// Close a specific WebSocket connection
        /// - Parameter url: The WebSocket URL to close
        @MainActor
        public static func closeConnection(for url: URL) {
            guard let connection = WebSocketDataSource.shared.getAllConnections().first(where: { $0.url == url }) else {
                return
            }
            // Update connection status to closed
            WebSocketDataSource.shared.updateConnectionStatus(connection.id, status: .closed)
        }
    }
} 
