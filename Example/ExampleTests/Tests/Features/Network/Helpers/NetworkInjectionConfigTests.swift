//
//  NetworkInjectionConfigTests.swift
//  ExampleTests
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class NetworkInjectionConfigTests: XCTestCase {
    
    // MARK: - RequestDelayConfig Tests
    
    func testRequestDelayConfigFixedDelay() {
        let config = RequestDelayConfig(
            isEnabled: true,
            fixedDelay: 2.0
        )
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.fixedDelay, 2.0)
        XCTAssertEqual(config.getDelay(), 2.0)
    }
    
    func testRequestDelayConfigRandomDelay() {
        let config = RequestDelayConfig(
            isEnabled: true,
            fixedDelay: nil,
            minDelay: 1.0,
            maxDelay: 3.0
        )
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertNil(config.fixedDelay)
        
        // Test multiple times to ensure it's in range
        for _ in 0..<10 {
            let delay = config.getDelay()
            XCTAssertGreaterThanOrEqual(delay, 1.0)
            XCTAssertLessThanOrEqual(delay, 3.0)
        }
    }
    
    func testRequestDelayConfigURLPatternMatching() {
        let config = RequestDelayConfig(
            isEnabled: true,
            fixedDelay: 1.0,
            urlPatterns: ["api.example.com"]
        )
        
        var request = URLRequest(url: URL(string: "https://api.example.com/users")!)
        XCTAssertTrue(config.shouldApply(to: request))
        
        request = URLRequest(url: URL(string: "https://other.com/users")!)
        XCTAssertFalse(config.shouldApply(to: request))
    }
    
    func testRequestDelayConfigHTTPMethodFiltering() {
        let config = RequestDelayConfig(
            isEnabled: true,
            fixedDelay: 1.0,
            httpMethods: ["POST", "PUT"]
        )
        
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        
        request.httpMethod = "POST"
        XCTAssertTrue(config.shouldApply(to: request))
        
        request.httpMethod = "GET"
        XCTAssertFalse(config.shouldApply(to: request))
    }
    
    func testRequestDelayConfigDisabled() {
        let config = RequestDelayConfig(
            isEnabled: false,
            fixedDelay: 1.0
        )
        
        let request = URLRequest(url: URL(string: "https://example.com/api")!)
        XCTAssertFalse(config.shouldApply(to: request))
    }
    
    // MARK: - NetworkFailureConfig Tests
    
    func testNetworkFailureConfigTimeout() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .timeout
        )
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.failureRate, 1.0)
        
        let error = config.getError() as NSError
        XCTAssertEqual(error.domain, NSURLErrorDomain)
        XCTAssertEqual(error.code, NSURLErrorTimedOut)
    }
    
    func testNetworkFailureConfigConnectionLost() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .connectionLost
        )
        
        let error = config.getError() as NSError
        XCTAssertEqual(error.domain, NSURLErrorDomain)
        XCTAssertEqual(error.code, NSURLErrorNetworkConnectionLost)
    }
    
    func testNetworkFailureConfigHTTPError() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .httpError(statusCode: 404)
        )
        
        let statusCode = config.getHTTPStatusCode()
        XCTAssertEqual(statusCode, 404)
    }
    
    func testNetworkFailureConfigRandomHTTPError() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .httpError(statusCode: nil),
            customStatusCodes: [400, 404, 500]
        )
        
        // Test multiple times to ensure it's from the list
        for _ in 0..<10 {
            if let statusCode = config.getHTTPStatusCode() {
                XCTAssertTrue([400, 404, 500].contains(statusCode))
            }
        }
    }
    
    func testNetworkFailureConfigCustomError() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .custom(
                domain: "com.test",
                code: 1001,
                description: "Test error"
            )
        )
        
        let error = config.getError() as NSError
        XCTAssertEqual(error.domain, "com.test")
        XCTAssertEqual(error.code, 1001)
        XCTAssertEqual(error.localizedDescription, "Test error")
    }
    
    func testNetworkFailureConfigFailureRateClamping() {
        var config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.5, // Over 1.0
            failureType: .timeout
        )
        XCTAssertEqual(config.failureRate, 1.0)
        
        config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: -0.5, // Under 0.0
            failureType: .timeout
        )
        XCTAssertEqual(config.failureRate, 0.0)
    }
    
    func testNetworkFailureConfigURLPatternMatching() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .timeout,
            urlPatterns: ["*/api/*"]
        )
        
        let request = URLRequest(url: URL(string: "https://example.com/api/users")!)
        
        // Since failure rate is 1.0, it should always inject
        XCTAssertTrue(config.shouldInjectFailure(for: request))
    }
    
    func testNetworkFailureConfigHTTPMethodFiltering() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 1.0,
            failureType: .timeout,
            httpMethods: ["POST"]
        )
        
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"
        
        XCTAssertTrue(config.shouldInjectFailure(for: request))
        
        request.httpMethod = "GET"
        XCTAssertFalse(config.shouldInjectFailure(for: request))
    }
    
    func testNetworkFailureConfigFailureRateProbability() {
        let config = NetworkFailureConfig(
            isEnabled: true,
            failureRate: 0.5,
            failureType: .timeout
        )
        
        let request = URLRequest(url: URL(string: "https://example.com/api")!)
        
        // Test multiple times - with 50% rate, we should see both true and false
        // (statistically, though individual tests might vary)
        var trueCount = 0
        var falseCount = 0
        
        for _ in 0..<100 {
            if config.shouldInjectFailure(for: request) {
                trueCount += 1
            } else {
                falseCount += 1
            }
        }
        
        // With 100 iterations at 50% rate, expect roughly 30-70 split
        XCTAssertGreaterThan(trueCount, 20)
        XCTAssertGreaterThan(falseCount, 20)
    }
    
    func testNetworkFailureConfigDisabled() {
        let config = NetworkFailureConfig(
            isEnabled: false,
            failureRate: 1.0,
            failureType: .timeout
        )
        
        let request = URLRequest(url: URL(string: "https://example.com/api")!)
        XCTAssertFalse(config.shouldInjectFailure(for: request))
    }
    
    // MARK: - All Failure Types Test
    
    func testAllFailureTypes() {
        let failureTypes: [NetworkFailureConfig.FailureType] = [
            .timeout,
            .connectionLost,
            .notConnectedToInternet,
            .cannotFindHost,
            .dnsLookupFailed,
            .httpError(statusCode: 500),
            .sslError,
            .cancelled,
            .custom(domain: "test", code: 999, description: "Test")
        ]
        
        for failureType in failureTypes {
            let config = NetworkFailureConfig(
                isEnabled: true,
                failureRate: 1.0,
                failureType: failureType
            )
            
            let error = config.getError()
            XCTAssertNotNil(error)
        }
    }
}
