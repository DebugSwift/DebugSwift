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
        public var onlySchemes = CustomHTTPProtocolURLScheme.allCases.filter { $0 != .ws && $0 != .wss }
        public var delegate: CustomHTTPProtocolDelegate?
        public var encryptionService: EncryptionServiceProtocol = EncryptionService.shared
        public var isDecryptionEnabled = false
        
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
        
        // MARK: - Encryption/Decryption API
        
        /// Enable or disable response decryption
        public func setDecryptionEnabled(_ enabled: Bool) {
            isDecryptionEnabled = enabled
        }
        
        /// Register a decryption key for specific URL patterns
        public func registerDecryptionKey(for urlPattern: String, key: Data) {
            if let service = encryptionService as? EncryptionService {
                service.registerDecryptionKey(for: urlPattern, key: key)
            }
        }

        /// Register a custom decryptor for specific URL patterns
        public func registerCustomDecryptor(for urlPattern: String, decryptor: @escaping (Data) -> Data?) {
            encryptionService.registerCustomDecryptor(for: urlPattern, decryptor: decryptor)
        }
        
        /// Set a custom encryption service
        public func setEncryptionService(_ service: EncryptionServiceProtocol) {
            encryptionService = service
        }
    }
    
    // MARK: - App Groups Configuration
    
    public class Resources: @unchecked Sendable {
        public static let shared = Resources()
        private init() {
            // Private initializer for singleton
        }
        
        /// App Group identifiers that should be accessible in the file browser
        /// Example: ["group.com.yourcompany.yourapp", "group.com.yourcompany.shared"]
        public var appGroupIdentifiers: [String] = []
        
        /// Configure app group identifiers for file browser access
        /// - Parameter identifiers: Array of app group identifiers from your app's entitlements
        public func configureAppGroups(_ identifiers: [String]) {
            appGroupIdentifiers = identifiers
        }
        
        /// Add a single app group identifier
        /// - Parameter identifier: App group identifier to add
        public func addAppGroup(_ identifier: String) {
            if !appGroupIdentifiers.contains(identifier) {
                appGroupIdentifiers.append(identifier)
            }
        }
        
        /// Remove an app group identifier
        /// - Parameter identifier: App group identifier to remove
        public func removeAppGroup(_ identifier: String) {
            appGroupIdentifiers.removeAll { $0 == identifier }
        }
        
        /// Get accessible app group containers
        /// - Returns: Array of accessible app group identifiers with their URLs
        public func getAccessibleAppGroups() -> [(identifier: String, url: URL)] {
            return appGroupIdentifiers.compactMap { identifier in
                guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
                    return nil
                }
                return (identifier, url)
            }
        }
    }
}
