//
//  URLSessionDelegateRegistry.swift
//  DebugSwift
//
//  Created to fix issue #240 - URLSession delegate forwarding
//

import Foundation

/// Thread-safe registry to store original URLSession delegates
/// This allows CustomHTTPProtocol to forward authentication challenges and other
/// delegate calls to the application's original URLSession delegates
public final class URLSessionDelegateRegistry: @unchecked Sendable {
    public static let shared = URLSessionDelegateRegistry()
    
    private let lock = NSLock()
    // Store delegates with timestamp for prioritization (most recent first)
    private var delegates: [(delegate: WeakDelegate, timestamp: Date)] = []
    
    private init() {}
    
    /// Register a URLSession delegate for forwarding
    /// Call this after creating your URLSession with a custom delegate
    ///
    /// Example:
    /// ```swift
    /// class MyDelegate: NSObject, URLSessionDelegate {
    ///     func urlSession(_ session: URLSession, didReceive challenge: ...) { ... }
    /// }
    ///
    /// let delegate = MyDelegate()
    /// let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    /// URLSessionDelegateRegistry.shared.register(delegate: delegate)
    /// ```
    public func register(delegate: URLSessionDelegate) {
        lock.lock()
        defer { lock.unlock() }
        
        // Don't register DebugSwift's own delegates
        guard !(delegate is CustomHTTPProtocol) else { return }
        
        // Add to the list with current timestamp
        delegates.append((WeakDelegate(delegate: delegate), Date()))
        
        // Cleanup old/nil delegates periodically
        if delegates.count > 10 {
            cleanupInternal()
        }
    }
    
    /// Get all registered delegates (most recent first) for forwarding
    func getAllDelegates() -> [URLSessionDelegate] {
        lock.lock()
        defer { lock.unlock() }
        
        // Sort by timestamp descending (most recent first)
        return delegates
            .sorted { $0.timestamp > $1.timestamp }
            .compactMap { $0.delegate.delegate }
    }
    
    /// Get the most recently registered delegate
    func getMostRecentDelegate() -> URLSessionDelegate? {
        lock.lock()
        defer { lock.unlock() }
        
        return delegates
            .sorted { $0.timestamp > $1.timestamp }
            .first?.delegate.delegate
    }
    
    /// Remove nil delegates from the registry
    public func cleanup() {
        lock.lock()
        defer { lock.unlock() }
        cleanupInternal()
    }
    
    private func cleanupInternal() {
        delegates = delegates.filter { $0.delegate.delegate != nil }
    }
    
    private class WeakDelegate {
        weak var delegate: URLSessionDelegate?
        
        init(delegate: URLSessionDelegate) {
            self.delegate = delegate
        }
    }
}

// MARK: - URLSession Extension for Easy Registration

extension URLSession {
    /// Register this session's delegate with DebugSwift for authentication forwarding
    /// Call this after creating a URLSession with a custom delegate
    ///
    /// Example:
    /// ```swift
    /// let session = URLSession(configuration: .default, delegate: myDelegate, delegateQueue: nil)
    /// session.registerDelegateForDebugSwift()
    /// ```
    public func registerDelegateForDebugSwift() {
        if let delegate = self.delegate {
            URLSessionDelegateRegistry.shared.register(delegate: delegate)
        }
    }
    
    // Called internally by DebugSwift - no-op, kept for compatibility
    @objc
    static func enableDelegateCapture() {
        // No longer needed - registration is now explicit
    }
}

