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
        
        /// You can use exact URL (literal):
        /// ["https://api.example.com"]
        /// or a wildcard
        /// ["https://api.example.com/v1/orders/\*", "https://\*.example.com"]
        public var ignoredURLs = [String]()
        /// You can use exact URL (literal):
        /// ["https://api.example.com"]
        /// or a wildcard
        /// ["https://api.example.com/v1/orders/\*", "https://\*.example.com"]
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
        
        // MARK: - Network Injection API
        
        /// Enable request delay injection with a fixed delay
        /// - Parameters:
        ///   - delay: Fixed delay in seconds
        ///   - urlPatterns: Optional URL patterns to match (empty means all URLs)
        ///   - httpMethods: Optional HTTP methods to apply delay to (empty means all methods)
        public func enableRequestDelay(
            _ delay: TimeInterval,
            urlPatterns: [String] = [],
            httpMethods: [String] = []
        ) {
            let config = RequestDelayConfig(
                isEnabled: true,
                fixedDelay: delay,
                urlPatterns: urlPatterns,
                httpMethods: httpMethods
            )
            NetworkInjectionManager.shared.setDelayConfig(config)
        }
        
        /// Enable request delay injection with a random delay range
        /// - Parameters:
        ///   - minDelay: Minimum delay in seconds
        ///   - maxDelay: Maximum delay in seconds
        ///   - urlPatterns: Optional URL patterns to match (empty means all URLs)
        ///   - httpMethods: Optional HTTP methods to apply delay to (empty means all methods)
        public func enableRequestDelay(
            min minDelay: TimeInterval,
            max maxDelay: TimeInterval,
            urlPatterns: [String] = [],
            httpMethods: [String] = []
        ) {
            let config = RequestDelayConfig(
                isEnabled: true,
                fixedDelay: nil,
                minDelay: minDelay,
                maxDelay: maxDelay,
                urlPatterns: urlPatterns,
                httpMethods: httpMethods
            )
            NetworkInjectionManager.shared.setDelayConfig(config)
        }
        
        /// Disable request delay injection
        public func disableRequestDelay() {
            var config = NetworkInjectionManager.shared.getDelayConfig()
            config.isEnabled = false
            NetworkInjectionManager.shared.setDelayConfig(config)
        }
        
        /// Enable network failure injection
        /// - Parameters:
        ///   - failureRate: Failure rate from 0.0 to 1.0 (1.0 = 100% failure)
        ///   - failureType: Type of failure to inject
        ///   - urlPatterns: Optional URL patterns to match (empty means all URLs)
        ///   - httpMethods: Optional HTTP methods to apply failure to (empty means all methods)
        public func enableFailureInjection(
            failureRate: Double = 0.5,
            failureType: NetworkFailureConfig.FailureType = .timeout,
            urlPatterns: [String] = [],
            httpMethods: [String] = []
        ) {
            let config = NetworkFailureConfig(
                isEnabled: true,
                failureRate: failureRate,
                failureType: failureType,
                urlPatterns: urlPatterns,
                httpMethods: httpMethods
            )
            NetworkInjectionManager.shared.setFailureConfig(config)
        }
        
        /// Enable HTTP error injection with specific status codes
        /// - Parameters:
        ///   - failureRate: Failure rate from 0.0 to 1.0 (1.0 = 100% failure)
        ///   - statusCodes: Array of HTTP status codes to randomly return
        ///   - urlPatterns: Optional URL patterns to match (empty means all URLs)
        ///   - httpMethods: Optional HTTP methods to apply failure to (empty means all methods)
        public func enableHTTPErrorInjection(
            failureRate: Double = 0.5,
            statusCodes: [Int] = [400, 401, 403, 404, 500, 502, 503],
            urlPatterns: [String] = [],
            httpMethods: [String] = []
        ) {
            let config = NetworkFailureConfig(
                isEnabled: true,
                failureRate: failureRate,
                failureType: .httpError(statusCode: nil),
                urlPatterns: urlPatterns,
                httpMethods: httpMethods,
                customStatusCodes: statusCodes
            )
            NetworkInjectionManager.shared.setFailureConfig(config)
        }
        
        /// Disable network failure injection
        public func disableFailureInjection() {
            var config = NetworkInjectionManager.shared.getFailureConfig()
            config.isEnabled = false
            NetworkInjectionManager.shared.setFailureConfig(config)
        }
        
        /// Configure custom network injection settings
        /// - Parameters:
        ///   - delayConfig: Optional delay configuration
        ///   - failureConfig: Optional failure configuration
        public func configureNetworkInjection(
            delayConfig: RequestDelayConfig? = nil,
            failureConfig: NetworkFailureConfig? = nil
        ) {
            if let delay = delayConfig {
                NetworkInjectionManager.shared.setDelayConfig(delay)
            }
            if let failure = failureConfig {
                NetworkInjectionManager.shared.setFailureConfig(failure)
            }
        }
        
        // MARK: - Network History Management
        
        /// Clear all HTTP/HTTPS network request history
        /// Use this to clear the Network tab when switching environments or testing different scenarios
        ///
        /// Example:
        /// ```swift
        /// // Clear network history when switching from dev to prod
        /// DebugSwift.Network.shared.clearNetworkHistory()
        /// ```
        public func clearNetworkHistory() {
            HttpDatasource.shared.removeAll()
            NotificationCenter.default.post(
                name: NSNotification.Name("reloadHttp_DebugSwift"),
                object: nil
            )
        }
        
        /// Clear all WebSocket connection and frame history
        /// Use this to clear WebSocket data when switching environments
        ///
        /// Example:
        /// ```swift
        /// DebugSwift.Network.shared.clearWebSocketHistory()
        /// ```
        @MainActor
        public func clearWebSocketHistory() {
            WebSocketDataSource.shared.removeAllConnections()
        }
        
        /// Clear all network data including HTTP requests and WebSocket connections
        /// This is a convenience method that clears both HTTP and WebSocket history
        ///
        /// Example:
        /// ```swift
        /// // Clear all network data when switching stands (dev/prod)
        /// DebugSwift.Network.shared.clearAllNetworkData()
        /// ```
        @MainActor
        public func clearAllNetworkData() {
            clearNetworkHistory()
            clearWebSocketHistory()
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
        
        // MARK: - Manual URLSessionConfiguration Injection
        
        /// Manually inject CustomHTTPProtocol into an existing URLSessionConfiguration
        /// Use this when you need to inject DebugSwift into configurations created before setup() is called
        ///
        /// Example:
        /// ```swift
        /// let config = URLSessionConfiguration.default
        /// DebugSwift.Network.shared.injectIntoConfiguration(config)
        /// let session = URLSession(configuration: config)
        /// ```
        ///
        /// - Parameter configuration: The URLSessionConfiguration to inject into
        public func injectIntoConfiguration(_ configuration: URLSessionConfiguration) {
            var protocolClasses = configuration.protocolClasses ?? []
            
            // Only add if not already present
            if !protocolClasses.contains(where: { $0 == CustomHTTPProtocol.self }) {
                protocolClasses.insert(CustomHTTPProtocol.self, at: 0)
                configuration.protocolClasses = protocolClasses
            }
        }
        
        /// Manually inject CustomHTTPProtocol and return a new configuration
        /// Use this when you need a new configuration with DebugSwift already injected
        ///
        /// Example:
        /// ```swift
        /// let config = DebugSwift.Network.shared.defaultConfiguration()
        /// let session = URLSession(configuration: config)
        /// ```
        ///
        /// - Returns: A new URLSessionConfiguration with CustomHTTPProtocol injected
        public func defaultConfiguration() -> URLSessionConfiguration {
            let configuration = URLSessionConfiguration.default
            injectIntoConfiguration(configuration)
            return configuration
        }
        
        /// Manually inject CustomHTTPProtocol and return a new ephemeral configuration
        /// Use this when you need an ephemeral configuration with DebugSwift already injected
        ///
        /// Example:
        /// ```swift
        /// let config = DebugSwift.Network.shared.ephemeralConfiguration()
        /// let session = URLSession(configuration: config)
        /// ```
        ///
        /// - Returns: A new ephemeral URLSessionConfiguration with CustomHTTPProtocol injected
        public func ephemeralConfiguration() -> URLSessionConfiguration {
            let configuration = URLSessionConfiguration.ephemeral
            injectIntoConfiguration(configuration)
            return configuration
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
