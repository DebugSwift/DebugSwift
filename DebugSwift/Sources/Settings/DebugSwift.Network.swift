//
//  DebugSwift.Network.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public class Network: @unchecked Sendable {
        public static let shared = Network()
        private init() {
            // Private initializer for singleton
        }
        
        public var ignoredURLs = [String]()
        public var onlyURLs = [String]()
        public var onlySchemes = CustomHTTPProtocolURLScheme.allCases
        public var delegate: CustomHTTPProtocolDelegate?
        
        // MARK: - Threshold Limiter API
        
        /// Get or set the global request threshold
        public var threshold: Int {
            get {
                NetworkThresholdTracker.shared.getConfig().limit
            }
            set {
                NetworkThresholdTracker.shared.setThreshold(newValue)
            }
        }
        
        /// Enable request tracking
        public func enableRequestTracking() {
            NetworkThresholdTracker.shared.setTrackingEnabled(true)
        }
        
        /// Disable request tracking
        public func disableRequestTracking() {
            NetworkThresholdTracker.shared.setTrackingEnabled(false)
        }
        
        /// Set threshold with custom time window
        public func setThreshold(_ limit: Int, timeWindow: TimeInterval = 60.0) {
            NetworkThresholdTracker.shared.setThreshold(limit, timeWindow: timeWindow)
        }
        
        /// Configure alert settings
        public func setThresholdAlert(emoji: String, message: String) {
            NetworkThresholdTracker.shared.configureAlert(emoji: emoji, message: message)
        }
        
        /// Enable/disable request blocking when threshold is exceeded
        public func setRequestBlocking(_ enabled: Bool) {
            NetworkThresholdTracker.shared.setRequestBlocking(enabled)
        }
        
        /// Set threshold for specific endpoint
        public func setEndpointThreshold(_ endpoint: String, limit: Int, timeWindow: TimeInterval = 60.0) {
            NetworkThresholdTracker.shared.setEndpointThreshold(endpoint, limit: limit, timeWindow: timeWindow)
        }
        
        /// Get current request count
        public func getCurrentRequestCount(endpoint: String? = nil) -> Int {
            NetworkThresholdTracker.shared.getCurrentRequestCount(endpoint: endpoint)
        }
        
        /// Get breach history
        public func getBreachHistory() -> [NetworkThresholdTracker.ThresholdBreach] {
            NetworkThresholdTracker.shared.getBreachHistory()
        }
        
        /// Clear request history
        public func clearThresholdHistory() {
            NetworkThresholdTracker.shared.clearHistory()
        }
        
        /// Get detailed threshold logs
        public func getThresholdLogs() -> String {
            NetworkThresholdTracker.shared.getDetailedLogs()
        }
    }
}
