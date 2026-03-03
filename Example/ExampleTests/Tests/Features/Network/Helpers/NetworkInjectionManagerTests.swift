//
//  NetworkInjectionManagerTests.swift
//  ExampleTests
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class NetworkInjectionManagerTests: XCTestCase {
    
    var manager: NetworkInjectionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        manager = NetworkInjectionManager.shared
        
        // Reset to default state
        manager.setDelayConfig(RequestDelayConfig())
        manager.setFailureConfig(NetworkFailureConfig())
        manager.setRewriteConfig(ResponseBodyRewriteConfig())
    }
    
    // MARK: - Delay Config Tests
    
    func testSetDelayConfig() {
        let config = RequestDelayConfig(
            isEnabled: true,
            fixedDelay: 2.0
        )
        
        manager.setDelayConfig(config)
        
        let retrieved = manager.getDelayConfig()
        XCTAssertTrue(retrieved.isEnabled)
        XCTAssertEqual(retrieved.fixedDelay, 2.0)
    }
    
    func testApplyDelayWhenEnabled() {
        let config = RequestDelayConfig(
            isEnabled: true,
            fixedDelay: 0.1 // Use small delay for testing
        )
        manager.setDelayConfig(config)
        
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let start = Date()
        
        manager.applyDelayIfNeeded(for: request)
        
        let duration = Date().timeIntervalSince(start)
        XCTAssertGreaterThanOrEqual(duration, 0.1)
    }
    
    func testApplyDelayWhenDisabled() {
        let config = RequestDelayConfig(
            isEnabled: false,
            fixedDelay: 1.0
        )
        manager.setDelayConfig(config)
        
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let start = Date()
        
        manager.applyDelayIfNeeded(for: request)
        
        let duration = Date().timeIntervalSince(start)
        XCTAssertLessThan(duration, 0.1) // Should be instant
    }
    
    func testApplyDelayWithURLPattern() {
        let config = RequestDelayConfig(
            isEnabled: true,
            fixedDelay: 0.1,
            urlPatterns: ["api.example.com"]
        )
        manager.setDelayConfig(config)
        
        // Matching URL
        var request = URLRequest(url: URL(string: "https://api.example.com/users")!)
        var start = Date()
        manager.applyDelayIfNeeded(for: request)
        var duration = Date().timeIntervalSince(start)
        XCTAssertGreaterThanOrEqual(duration, 0.1)
        
        // Non-matching URL
        request = URLRequest(url: URL(string: "https://other.com/users")!)
        start = Date()
        manager.applyDelayIfNeeded(for: request)
        duration = Date().timeIntervalSince(start)
        XCTAssertLessThan(duration, 0.1)
    }
    
    // MARK: - Failure Config Tests
    
    func testSetFailureConfig() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .timeout
        )
        
        manager.setFailureConfig(config)
        
        let retrieved = manager.getFailureConfig()
        XCTAssertTrue(retrieved.isEnabled)
        XCTAssertEqual(retrieved.failureRate, 1.0)
    }
    
    func testShouldInjectFailureWhenEnabled() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .timeout
        )
        manager.setFailureConfig(config)
        
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let result = manager.shouldInjectFailure(for: request)
        
        XCTAssertTrue(result.shouldInject)
        XCTAssertNotNil(result.error)
        XCTAssertEqual((result.error as NSError?)?.code, NSURLErrorTimedOut)
    }
    
    func testShouldInjectFailureWhenDisabled() {
        let config = NetworkFailureConfig(
            isEnabled: false,
            failureRate: 1.0,
            failureType: .timeout
        )
        manager.setFailureConfig(config)
        
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let result = manager.shouldInjectFailure(for: request)
        
        XCTAssertFalse(result.shouldInject)
        XCTAssertNil(result.error)
    }
    
    func testShouldInjectHTTPError() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .httpError(statusCode: 404)
        )
        manager.setFailureConfig(config)
        
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let result = manager.shouldInjectFailure(for: request)
        
        XCTAssertTrue(result.shouldInject)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.statusCode, 404)
    }
    
    func testShouldInjectFailureWithURLPattern() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .timeout,
            urlPatterns: ["api.example.com"]
        )
        manager.setFailureConfig(config)
        
        // Matching URL
        var request = URLRequest(url: URL(string: "https://api.example.com/users")!)
        var result = manager.shouldInjectFailure(for: request)
        XCTAssertTrue(result.shouldInject)
        
        // Non-matching URL
        request = URLRequest(url: URL(string: "https://other.com/users")!)
        result = manager.shouldInjectFailure(for: request)
        XCTAssertFalse(result.shouldInject)
    }
    
    func testShouldInjectFailureWithHTTPMethod() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .timeout,
            httpMethods: ["POST"]
        )
        manager.setFailureConfig(config)
        
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        
        // Matching method
        request.httpMethod = "POST"
        var result = manager.shouldInjectFailure(for: request)
        XCTAssertTrue(result.shouldInject)
        
        // Non-matching method
        request.httpMethod = "GET"
        result = manager.shouldInjectFailure(for: request)
        XCTAssertFalse(result.shouldInject)
    }
    
    // MARK: - Rewrite Config Tests
    
    func testSetRewriteConfig() {
        let rule = ResponseBodyRewriteRule(
            urlPattern: "https://api.example.com/*",
            responseBody: "{\"ok\":true}"
        )
        let config = ResponseBodyRewriteConfig(isEnabled: true, rules: [rule])
        
        manager.setRewriteConfig(config)
        
        let retrieved = manager.getRewriteConfig()
        XCTAssertTrue(retrieved.isEnabled)
        XCTAssertEqual(retrieved.rules, [rule])
    }
    
    func testMatchingRewriteRule() {
        let firstRule = ResponseBodyRewriteRule(
            urlPattern: "https://api.example.com/v1/*",
            responseBody: "{\"version\":\"v1\"}"
        )
        let secondRule = ResponseBodyRewriteRule(
            urlPattern: "https://api.example.com/v2/*",
            responseBody: "{\"version\":\"v2\"}"
        )
        let config = ResponseBodyRewriteConfig(isEnabled: true, rules: [firstRule, secondRule])
        manager.setRewriteConfig(config)
        
        let request = URLRequest(url: URL(string: "https://api.example.com/v2/users")!)
        let matched = manager.matchingRewriteRule(for: request)
        
        XCTAssertEqual(matched, secondRule)
    }
}
