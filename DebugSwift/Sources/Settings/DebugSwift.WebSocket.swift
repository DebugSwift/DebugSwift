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
        /// This is automatically called when DebugSwift is set up, but you can call it manually if needed
        public static func enableMonitoring() {
            WebSocketMonitor.shared.enable()
        }
        
        /// Disable WebSocket monitoring
        /// This will stop intercepting new WebSocket traffic but preserve existing data
        public static func disableMonitoring() {
            WebSocketMonitor.shared.disable()
        }
        
        /// Check if WebSocket monitoring is currently enabled
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
    }
} 
