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
    
    private enum PersistenceKeys {
        static let rewriteRules = "DebugSwift.NetworkInjection.RewriteRules"
        static let rewriteAutoEnableOnRun = "DebugSwift.NetworkInjection.RewriteAutoEnableOnRun"
        static let rewriteShortCircuitEnabled = "DebugSwift.NetworkInjection.RewriteShortCircuitEnabled"
    }
    
    private let queue = DispatchQueue(label: "com.debugswift.injection", attributes: .concurrent)
    private var _delayConfig: RequestDelayConfig = RequestDelayConfig()
    private var _failureConfig: NetworkFailureConfig = NetworkFailureConfig()
    private var _rewriteConfig: ResponseBodyRewriteConfig = ResponseBodyRewriteConfig()
    private var _rewriteRulesSnapshot: [ResponseBodyRewriteRule] = []
    
    private init() {
        _rewriteConfig.isEnabled = shouldAutoEnableRewriteOnRun()
        _rewriteConfig.rules = loadPersistedRewriteRules().map { rule in
            var normalizedRule = rule
            normalizedRule.matchType = rule.urlPattern.contains("*") || rule.urlPattern.contains("?") ? .wildcard : .exact
            return normalizedRule
        }
        _rewriteRulesSnapshot = _rewriteConfig.rules
    }
    
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
        queue.sync(flags: .barrier) {
            let previousRules = _rewriteConfig.rules
            var normalizedConfig = config
            normalizedConfig.rules = config.rules.map { rule in
                var normalizedRule = rule
                normalizedRule.matchType = rule.urlPattern.contains("*") || rule.urlPattern.contains("?") ? .wildcard : .exact
                return normalizedRule
            }
            _rewriteConfig = normalizedConfig
            _rewriteRulesSnapshot = normalizedConfig.rules
            if previousRules != normalizedConfig.rules {
                persistRewriteRules(normalizedConfig.rules)
            }
        }
        Debug.print("✏️ Rewrite config updated: enabled=\(config.isEnabled), rules=\(config.rules.count)")
    }
    
    func getRewriteConfig() -> ResponseBodyRewriteConfig {
        return queue.sync { _rewriteConfig }
    }
    
    func matchingRewriteRule(for request: URLRequest) -> ResponseBodyRewriteRule? {
        guard let url = request.url else { return nil }
        let (isEnabled, rules): (Bool, [ResponseBodyRewriteRule]) = queue.sync {
            (_rewriteConfig.isEnabled, _rewriteRulesSnapshot)
        }
        guard isEnabled else { return nil }

        let requestURLLowercased = url.absoluteString.lowercased()
        for rule in rules where rule.isEnabled {
            switch rule.matchType {
            case .exact:
                if requestURLLowercased == rule.urlPattern.lowercased() {
                    return rule
                }
            case .wildcard:
                if url.matches(
                    wildcardPattern: rule.urlPattern,
                    strategy: .full,
                    queryStrategy: .exact
                ) {
                    return rule
                }
            }
        }

        return nil
    }

    func setRewriteAutoEnableOnRun(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: PersistenceKeys.rewriteAutoEnableOnRun)
    }

    func shouldAutoEnableRewriteOnRun() -> Bool {
        UserDefaults.standard.bool(forKey: PersistenceKeys.rewriteAutoEnableOnRun)
    }
    
    func setRewriteShortCircuitEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: PersistenceKeys.rewriteShortCircuitEnabled)
    }
    
    func isRewriteShortCircuitEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: PersistenceKeys.rewriteShortCircuitEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PersistenceKeys.rewriteShortCircuitEnabled)
    }
    
    private func loadPersistedRewriteRules() -> [ResponseBodyRewriteRule] {
        if let data = UserDefaults.standard.data(forKey: PersistenceKeys.rewriteRules),
           let decoded = try? JSONDecoder().decode([ResponseBodyRewriteRule].self, from: data) {
            return decoded
        }
        return []
    }
    
    private func persistRewriteRules(_ rules: [ResponseBodyRewriteRule]) {
        if rules.isEmpty {
            UserDefaults.standard.removeObject(forKey: PersistenceKeys.rewriteRules)
            return
        }
        
        if let encoded = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(encoded, forKey: PersistenceKeys.rewriteRules)
        }
    }
}
