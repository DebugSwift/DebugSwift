//
//  NetworkInjectionManager.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import Foundation

/// Manager for network request/response injection behaviors
final class NetworkInjectionManager: @unchecked Sendable {
    static let shared = NetworkInjectionManager()
    
    private let queue = DispatchQueue(label: "com.debugswift.injection", attributes: .concurrent)
    private var _delayConfig: RequestDelayConfig = RequestDelayConfig()
    private var _failureConfig: NetworkFailureConfig = NetworkFailureConfig()
    private var _rewriteConfig: ResponseBodyRewriteConfig = ResponseBodyRewriteConfig()
    
    private init() {}
    
    // MARK: - Delay Injection
    
    func setDelayConfig(_ config: RequestDelayConfig) {
        queue.async(flags: .barrier) { [weak self] in
            self?._delayConfig = config
        }
        Debug.print("🕒 Delay injection config updated: enabled=\(config.isEnabled)")
    }
    
    func getDelayConfig() -> RequestDelayConfig {
        return queue.sync { _delayConfig }
    }
    
    /// Apply delay if configured for this request
    func applyDelayIfNeeded(for request: URLRequest) {
        let config = getDelayConfig()
        guard config.shouldApply(to: request) else { return }
        
        let delay = config.getDelay()
        Debug.print("⏱️ Injecting \(delay)s delay for \(request.url?.absoluteString ?? "unknown URL")")
        
        Thread.sleep(forTimeInterval: delay)
    }
    
    // MARK: - Failure Injection
    
    func setFailureConfig(_ config: NetworkFailureConfig) {
        queue.async(flags: .barrier) { [weak self] in
            self?._failureConfig = config
        }
        Debug.print("💥 Failure injection config updated: enabled=\(config.isEnabled), rate=\(config.failureRate)")
    }
    
    func getFailureConfig() -> NetworkFailureConfig {
        return queue.sync { _failureConfig }
    }
    
    /// Check if failure should be injected for this request
    func shouldInjectFailure(for request: URLRequest) -> (shouldInject: Bool, error: Error?, statusCode: Int?) {
        let config = getFailureConfig()
        guard config.shouldInjectFailure(for: request) else {
            return (false, nil, nil)
        }
        
        let error = config.getError()
        let statusCode = config.getHTTPStatusCode()
        
        Debug.print("💥 Injecting failure for \(request.url?.absoluteString ?? "unknown URL"): \(error.localizedDescription)")
        
        return (true, error, statusCode)
    }
    
    // MARK: - Response Body Rewrite
    
    func setRewriteConfig(_ config: ResponseBodyRewriteConfig) {
        queue.async(flags: .barrier) { [weak self] in
            self?._rewriteConfig = config
        }
        Debug.print("✏️ Rewrite config updated: enabled=\(config.isEnabled), rules=\(config.rules.count)")
    }
    
    func getRewriteConfig() -> ResponseBodyRewriteConfig {
        return queue.sync { _rewriteConfig }
    }
    
    func matchingRewriteRule(for request: URLRequest) -> ResponseBodyRewriteRule? {
        let config = getRewriteConfig()
        return config.matchingRule(for: request)
    }
}
