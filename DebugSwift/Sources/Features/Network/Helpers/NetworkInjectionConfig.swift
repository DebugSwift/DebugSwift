//
//  NetworkInjectionConfig.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import Foundation

/// Configuration for network request delay injection
public struct RequestDelayConfig: Sendable {
    /// Whether delay injection is enabled
    public var isEnabled: Bool
    
    /// Fixed delay in seconds (if specified, overrides min/max range)
    public var fixedDelay: TimeInterval?
    
    /// Minimum delay in seconds (used when fixedDelay is nil)
    public var minDelay: TimeInterval
    
    /// Maximum delay in seconds (used when fixedDelay is nil)
    public var maxDelay: TimeInterval
    
    /// URL patterns to match (empty means all URLs)
    public var urlPatterns: [String]
    
    /// HTTP methods to apply delay to (empty means all methods)
    public var httpMethods: [String]
    
    public init(
        isEnabled: Bool = false,
        fixedDelay: TimeInterval? = nil,
        minDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 3.0,
        urlPatterns: [String] = [],
        httpMethods: [String] = []
    ) {
        self.isEnabled = isEnabled
        self.fixedDelay = fixedDelay
        self.minDelay = minDelay
        self.maxDelay = maxDelay
        self.urlPatterns = urlPatterns
        self.httpMethods = httpMethods
    }
    
    /// Get the actual delay to apply
    func getDelay() -> TimeInterval {
        if let fixed = fixedDelay {
            return fixed
        }
        return TimeInterval.random(in: minDelay...maxDelay)
    }
    
    /// Check if this config should apply to a given request
    func shouldApply(to request: URLRequest) -> Bool {
        guard isEnabled else { return false }
        
        // Check URL patterns
        if !urlPatterns.isEmpty {
            guard let urlString = request.url?.absoluteString else { return false }
            let matches = urlPatterns.contains { pattern in
                urlString.contains(pattern) || urlString.matches(pattern: pattern)
            }
            if !matches { return false }
        }
        
        // Check HTTP methods
        if !httpMethods.isEmpty {
            guard let method = request.httpMethod else { return false }
            if !httpMethods.contains(method) { return false }
        }
        
        return true
    }
}

/// Configuration for network failure injection
public struct NetworkFailureConfig: Sendable {
    /// Whether failure injection is enabled
    public var isEnabled: Bool
    
    /// Failure rate (0.0 to 1.0, where 1.0 = 100% failure)
    public var failureRate: Double
    
    /// Type of failure to inject
    public var failureType: FailureType
    
    /// URL patterns to match (empty means all URLs)
    public var urlPatterns: [String]
    
    /// HTTP methods to apply failure to (empty means all methods)
    public var httpMethods: [String]
    
    /// Custom HTTP status codes for HTTP error failures
    public var customStatusCodes: [Int]
    
    public enum FailureType: Sendable {
        /// Timeout error
        case timeout
        
        /// Network connection lost
        case connectionLost
        
        /// No internet connection
        case notConnectedToInternet
        
        /// Cannot find host
        case cannotFindHost
        
        /// DNS lookup failed
        case dnsLookupFailed
        
        /// HTTP error with specific status codes (e.g., 400, 401, 403, 404, 500, 502, 503)
        case httpError(statusCode: Int?)
        
        /// SSL/TLS error
        case sslError
        
        /// Request cancelled
        case cancelled
        
        /// Custom error with domain and code
        case custom(domain: String, code: Int, description: String)
        
        func toError() -> Error {
            switch self {
            case .timeout:
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorTimedOut,
                    userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
                )
            case .connectionLost:
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorNetworkConnectionLost,
                    userInfo: [NSLocalizedDescriptionKey: "The network connection was lost."]
                )
            case .notConnectedToInternet:
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorNotConnectedToInternet,
                    userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
                )
            case .cannotFindHost:
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorCannotFindHost,
                    userInfo: [NSLocalizedDescriptionKey: "A server with the specified hostname could not be found."]
                )
            case .dnsLookupFailed:
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorDNSLookupFailed,
                    userInfo: [NSLocalizedDescriptionKey: "The DNS lookup failed."]
                )
            case .httpError:
                // This will be handled separately with a mock response
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorBadServerResponse,
                    userInfo: [NSLocalizedDescriptionKey: "The server responded with an error."]
                )
            case .sslError:
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorSecureConnectionFailed,
                    userInfo: [NSLocalizedDescriptionKey: "A secure connection could not be established."]
                )
            case .cancelled:
                return NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorCancelled,
                    userInfo: [NSLocalizedDescriptionKey: "The request was cancelled."]
                )
            case .custom(let domain, let code, let description):
                return NSError(
                    domain: domain,
                    code: code,
                    userInfo: [NSLocalizedDescriptionKey: description]
                )
            }
        }
    }
    
    public init(
        isEnabled: Bool = false,
        failureRate: Double = 0.5,
        failureType: FailureType = .timeout,
        urlPatterns: [String] = [],
        httpMethods: [String] = [],
        customStatusCodes: [Int] = [400, 401, 403, 404, 500, 502, 503]
    ) {
        self.isEnabled = isEnabled
        self.failureRate = max(0.0, min(1.0, failureRate))
        self.failureType = failureType
        self.urlPatterns = urlPatterns
        self.httpMethods = httpMethods
        self.customStatusCodes = customStatusCodes
    }
    
    /// Check if failure should be injected for this request
    func shouldInjectFailure(for request: URLRequest) -> Bool {
        guard isEnabled else { return false }
        
        // Check URL patterns
        if !urlPatterns.isEmpty {
            guard let urlString = request.url?.absoluteString else { return false }
            let matches = urlPatterns.contains { pattern in
                urlString.contains(pattern) || urlString.matches(pattern: pattern)
            }
            if !matches { return false }
        }
        
        // Check HTTP methods
        if !httpMethods.isEmpty {
            guard let method = request.httpMethod else { return false }
            if !httpMethods.contains(method) { return false }
        }
        
        // Apply failure rate
        return Double.random(in: 0...1) <= failureRate
    }
    
    /// Get the error to inject
    func getError() -> Error {
        return failureType.toError()
    }
    
    /// Get HTTP status code for HTTP error type
    func getHTTPStatusCode() -> Int? {
        if case .httpError(let statusCode) = failureType {
            if let code = statusCode {
                return code
            }
            // Return random status code from custom codes
            return customStatusCodes.randomElement() ?? 500
        }
        return nil
    }
}

// MARK: - String Pattern Matching Extension

private extension String {
    func matches(pattern: String) -> Bool {
        // Simple wildcard matching (* and ?)
        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")
        
        guard let regex = try? NSRegularExpression(pattern: "^" + regexPattern + "$") else {
            return false
        }
        
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, range: range) != nil
    }
}
