//
//  NetworkThresholdTracker.swift
//  DebugSwift
//
//  Created by DebugSwift on 03/06/25.
//

import Foundation
import UIKit

/// Tracks network requests and manages threshold limits
public final class NetworkThresholdTracker: @unchecked Sendable {
    static let shared = NetworkThresholdTracker()
    
    // MARK: - Properties
    
    /// UserDefaults keys
    private enum UserDefaultsKeys {
        static let isEnabled = "DebugSwift.NetworkThreshold.isEnabled"
        static let limit = "DebugSwift.NetworkThreshold.limit"
        static let timeWindow = "DebugSwift.NetworkThreshold.timeWindow"
        static let shouldBlockRequests = "DebugSwift.NetworkThreshold.shouldBlockRequests"
        static let alertEmoji = "DebugSwift.NetworkThreshold.alertEmoji"
        static let alertMessage = "DebugSwift.NetworkThreshold.alertMessage"
        static let endpointThresholds = "DebugSwift.NetworkThreshold.endpointThresholds"
    }
    
    /// Request threshold configuration
    struct ThresholdConfig: Codable {
        var limit: Int = 1000
        var timeWindow: TimeInterval = 60.0 // Default: 1 minute
        var isEnabled: Bool = false
        var shouldBlockRequests: Bool = false
        var alertEmoji: String = "⚠️"
        var alertMessage: String = "Request limit exceeded!"
    }
    
    /// Request tracking entry
    struct RequestEntry {
        let url: URL
        let timestamp: Date
        let endpoint: String
    }
    
    /// Threshold breach record
    public struct ThresholdBreach: Sendable {
        public let timestamp: Date
        public let requestCount: Int
        public let threshold: Int
        public let endpoint: String?
        public let message: String
    }
    
    private var config = ThresholdConfig()
    private var requestHistory = [RequestEntry]()
    private var breachHistory = [ThresholdBreach]()
    private var endpointThresholds = [String: ThresholdConfig]()
    private let queue = DispatchQueue(label: "com.debugswift.network.threshold", attributes: .concurrent)
    private let userDefaults = UserDefaults.standard
    
    // Cached enabled state for fast access without queue operations
    private var _isEnabledCache: Bool = false
    private var _shouldBlockCache: Bool = false
    
    private init() {
        loadConfiguration()
        updateCacheValues()
    }
    
    // MARK: - Private Cache Management
    
    private func updateCacheValues() {
        _isEnabledCache = config.isEnabled
        _shouldBlockCache = config.shouldBlockRequests
    }
    
    // MARK: - Public Methods
    
    /// Set the global request threshold
    func setThreshold(_ limit: Int, timeWindow: TimeInterval = 60.0) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.config.limit = limit
            self.config.timeWindow = timeWindow
            self.updateCacheValues()
            self.saveConfiguration()
        }
    }
    
    /// Enable or disable request tracking
    func setTrackingEnabled(_ enabled: Bool) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.config.isEnabled = enabled
            self.updateCacheValues()
            if !enabled {
                self.requestHistory.removeAll()
            }
            self.saveConfiguration()
        }
    }
    
    /// Configure alert settings
    func configureAlert(emoji: String, message: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.config.alertEmoji = emoji
            self.config.alertMessage = message
            self.saveConfiguration()
        }
    }
    
    /// Set threshold for specific endpoint
    func setEndpointThreshold(_ endpoint: String, limit: Int, timeWindow: TimeInterval = 60.0) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            var endpointConfig = ThresholdConfig()
            endpointConfig.limit = limit
            endpointConfig.timeWindow = timeWindow
            endpointConfig.isEnabled = true
            self.endpointThresholds[endpoint] = endpointConfig
            self.saveConfiguration()
        }
    }
    
    /// Track a network request
    func trackRequest(url: URL) {
        // Fast check using cached value to avoid queue operations
        guard _isEnabledCache else { return }
        
        // Ensure we don't crash on invalid URLs
        guard url.absoluteString.count > 0 else { return }
        
        let endpoint = extractEndpoint(from: url)
        let entry = RequestEntry(url: url, timestamp: Date(), endpoint: endpoint)
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.requestHistory.append(entry)
            self.cleanupOldRequests()
            self.checkThreshold(for: endpoint)
        }
    }
    
    /// Get current request count
    func getCurrentRequestCount(endpoint: String? = nil) -> Int {
        // Fast check using cached value to avoid unnecessary queue operations
        guard _isEnabledCache else { return 0 }
        
        return queue.sync { [weak self] in
            guard let self = self else { return 0 }
            let now = Date()
            let timeWindow = endpoint.flatMap { self.endpointThresholds[$0]?.timeWindow } ?? self.config.timeWindow
            
            return self.requestHistory.filter { entry in
                let isWithinWindow = now.timeIntervalSince(entry.timestamp) <= timeWindow
                let matchesEndpoint = endpoint == nil || entry.endpoint == endpoint
                return isWithinWindow && matchesEndpoint
            }.count
        }
    }
    
    /// Get breach history
    func getBreachHistory() -> [ThresholdBreach] {
        return queue.sync { [weak self] in
            return self?.breachHistory ?? []
        }
    }
    
    /// Clear request history
    func clearHistory() {
        queue.async(flags: .barrier) { [weak self] in
            self?.requestHistory.removeAll()
            self?.breachHistory.removeAll()
        }
    }
    
    /// Check if requests should be blocked
    func shouldBlockRequest(url: URL) -> Bool {
        // Fast check using cached values to avoid queue operations
        guard _isEnabledCache && _shouldBlockCache else { return false }
        
        // Ensure we don't crash on invalid URLs
        guard url.absoluteString.count > 0 else { return false }
        
        let endpoint = extractEndpoint(from: url)
        let currentCount = getCurrentRequestCount(endpoint: endpoint)
        let threshold = endpointThresholds[endpoint]?.limit ?? config.limit
        
        return currentCount >= threshold
    }
    
    /// Enable/disable request blocking when threshold is exceeded
    func setRequestBlocking(_ enabled: Bool) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.config.shouldBlockRequests = enabled
            self.updateCacheValues()
            self.saveConfiguration()
        }
    }
    
    /// Get detailed logs
    func getDetailedLogs() -> String {
        queue.sync {
            var logs = "=== Network Request Threshold Logs ===\n\n"
            
            logs += "Configuration:\n"
            logs += "- Global Threshold: \(config.limit) requests per \(config.timeWindow)s\n"
            logs += "- Tracking Enabled: \(config.isEnabled)\n"
            logs += "- Request Blocking: \(config.shouldBlockRequests)\n\n"
            
            logs += "Endpoint Thresholds:\n"
            for (endpoint, config) in endpointThresholds {
                logs += "- \(endpoint): \(config.limit) per \(config.timeWindow)s\n"
            }
            logs += "\n"
            
            // Calculate current count directly to avoid deadlock
            let now = Date()
            let currentCount = requestHistory.filter { entry in
                now.timeIntervalSince(entry.timestamp) <= config.timeWindow
            }.count
            
            logs += "Current Request Count: \(currentCount)\n\n"
            
            logs += "Breach History:\n"
            for breach in breachHistory.suffix(10) {
                logs += "- \(breach.timestamp.formatted()): \(breach.message)\n"
            }
            
            return logs
        }
    }
    
    // MARK: - Public Accessors
    
    /// Get current configuration
    func getConfig() -> ThresholdConfig {
        return queue.sync { [weak self] in
            return self?.config ?? ThresholdConfig()
        }
    }
    
    /// Get endpoint thresholds
    func getEndpointThresholds() -> [String: ThresholdConfig] {
        return queue.sync { [weak self] in
            return self?.endpointThresholds ?? [:]
        }
    }
    
    /// Remove threshold for specific endpoint
    func removeEndpointThreshold(_ endpoint: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.endpointThresholds.removeValue(forKey: endpoint)
            self?.saveConfiguration()
        }
    }
    
    /// Clear all endpoint thresholds
    func clearEndpointThresholds() {
        queue.async(flags: .barrier) { [weak self] in
            self?.endpointThresholds.removeAll()
            self?.saveConfiguration()
        }
    }
    
    // MARK: - Private Methods
    
    private func cleanupOldRequests() {
        let now = Date()
        requestHistory.removeAll { entry in
            now.timeIntervalSince(entry.timestamp) > max(config.timeWindow, 300) // Keep max 5 minutes
        }
    }
    
    private func checkThreshold(for endpoint: String?) {
        // Calculate count directly without queue.sync to avoid deadlock
        let now = Date()
        let timeWindow = endpoint.flatMap { endpointThresholds[$0]?.timeWindow } ?? config.timeWindow
        
        let currentCount = requestHistory.filter { entry in
            let isWithinWindow = now.timeIntervalSince(entry.timestamp) <= timeWindow
            let matchesEndpoint = endpoint == nil || entry.endpoint == endpoint
            return isWithinWindow && matchesEndpoint
        }.count
        
        let threshold = endpoint.flatMap { endpointThresholds[$0]?.limit } ?? config.limit
        let alertConfig = endpoint.flatMap { endpointThresholds[$0] } ?? config
        
        if currentCount > threshold {
            let breach = ThresholdBreach(
                timestamp: Date(),
                requestCount: currentCount,
                threshold: threshold,
                endpoint: endpoint,
                message: "\(alertConfig.alertEmoji) \(alertConfig.alertMessage) (\(currentCount)/\(threshold))"
            )
            
            breachHistory.append(breach)
            triggerAlert(breach)
        }
    }
    
    private func triggerAlert(_ breach: ThresholdBreach) {
        // Extract values before async block to avoid data race
        let timestamp = breach.timestamp
        let requestCount = breach.requestCount 
        let threshold = breach.threshold
        let endpoint = breach.endpoint ?? ""
        let message = breach.message
        
        // Send notification for UI update
        DispatchQueue.main.async {
            let breachInfo: [String: Any] = [
                "timestamp": timestamp,
                "requestCount": requestCount,
                "threshold": threshold,
                "endpoint": endpoint,
                "message": message
            ]
            
            NotificationCenter.default.post(
                name: .networkThresholdExceeded,
                object: nil,
                userInfo: breachInfo
            )
            
            // Animate floating button
            FloatViewManager.animate(success: false)
            
            // Log to console
            Debug.print("🚨 Network Threshold Alert: \(message)")
        }
    }
    
    private func extractEndpoint(from url: URL) -> String {
        // Extract meaningful endpoint from URL
        let components = url.pathComponents.filter { $0 != "/" }
        if components.isEmpty {
            return url.host ?? "unknown"
        }
        
        // Return first two path components for endpoint identification
        return components.prefix(2).joined(separator: "/")
    }
    
    // MARK: - Private Methods - Configuration Persistence
    
    private func loadConfiguration() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Load main config
            if let savedLimit = self.userDefaults.object(forKey: UserDefaultsKeys.limit) as? Int {
                self.config.limit = savedLimit
            }
            if let savedTimeWindow = self.userDefaults.object(forKey: UserDefaultsKeys.timeWindow) as? TimeInterval {
                self.config.timeWindow = savedTimeWindow
            }
            if let savedIsEnabled = self.userDefaults.object(forKey: UserDefaultsKeys.isEnabled) as? Bool {
                self.config.isEnabled = savedIsEnabled
            }
            if let savedShouldBlock = self.userDefaults.object(forKey: UserDefaultsKeys.shouldBlockRequests) as? Bool {
                self.config.shouldBlockRequests = savedShouldBlock
            }
            if let savedEmoji = self.userDefaults.string(forKey: UserDefaultsKeys.alertEmoji) {
                self.config.alertEmoji = savedEmoji
            }
            if let savedMessage = self.userDefaults.string(forKey: UserDefaultsKeys.alertMessage) {
                self.config.alertMessage = savedMessage
            }
            
            // Load endpoint thresholds
            if let data = self.userDefaults.data(forKey: UserDefaultsKeys.endpointThresholds),
               let decoded = try? JSONDecoder().decode([String: ThresholdConfig].self, from: data) {
                self.endpointThresholds = decoded
            }
            
            // Update cache values after loading configuration
            self.updateCacheValues()
        }
    }
    
    private func saveConfiguration() {
        // Save main config
        userDefaults.set(config.limit, forKey: UserDefaultsKeys.limit)
        userDefaults.set(config.timeWindow, forKey: UserDefaultsKeys.timeWindow)
        userDefaults.set(config.isEnabled, forKey: UserDefaultsKeys.isEnabled)
        userDefaults.set(config.shouldBlockRequests, forKey: UserDefaultsKeys.shouldBlockRequests)
        userDefaults.set(config.alertEmoji, forKey: UserDefaultsKeys.alertEmoji)
        userDefaults.set(config.alertMessage, forKey: UserDefaultsKeys.alertMessage)
        
        // Save endpoint thresholds
        if let encoded = try? JSONEncoder().encode(endpointThresholds) {
            userDefaults.set(encoded, forKey: UserDefaultsKeys.endpointThresholds)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkThresholdExceeded = Notification.Name("networkThresholdExceeded_DebugSwift")
    static let networkThresholdUpdated = Notification.Name("networkThresholdUpdated_DebugSwift")
} 
