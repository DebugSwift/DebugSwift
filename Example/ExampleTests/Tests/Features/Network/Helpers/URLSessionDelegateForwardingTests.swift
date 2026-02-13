//
//  URLSessionDelegateForwardingTests.swift
//  DebugSwift
//
//  Created to test fix for issue #240 - URLSessionDelegate forwarding
//

import XCTest
@testable import DebugSwift

final class URLSessionDelegateForwardingTests: XCTestCase {
    
    private var testDelegate: MockURLSessionDelegate!
    
    override func setUp() {
        super.setUp()
        // Clean registry before each test
        URLSessionDelegateRegistry.shared.cleanup()
        testDelegate = MockURLSessionDelegate()
    }
    
    override func tearDown() {
        testDelegate = nil
        // Cleanup the registry
        URLSessionDelegateRegistry.shared.cleanup()
        super.tearDown()
    }
    
    // MARK: - Registry Tests
    
    func testDelegateRegistry_storesDelegate() {
        // When
        URLSessionDelegateRegistry.shared.register(delegate: testDelegate)
        
        // Then
        let retrievedDelegate = URLSessionDelegateRegistry.shared.getMostRecentDelegate()
        XCTAssertNotNil(retrievedDelegate)
        XCTAssertTrue(retrievedDelegate is MockURLSessionDelegate)
    }
    
    func testDelegateRegistry_returnsMostRecentDelegate() {
        // Given
        let delegate1 = MockURLSessionDelegate()
        let delegate2 = MockURLSessionDelegate()
        
        // When
        URLSessionDelegateRegistry.shared.register(delegate: delegate1)
        // Small delay to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.01)
        URLSessionDelegateRegistry.shared.register(delegate: delegate2)
        
        // Then
        let retrieved = URLSessionDelegateRegistry.shared.getMostRecentDelegate()
        XCTAssertTrue(retrieved === delegate2)
    }

    // MARK: - URLSession Registration Tests
    
    func testURLSession_manualRegistration() {
        // Given
        let delegate = MockURLSessionDelegate()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        // When
        session.registerDelegateForDebugSwift()
        
        // Then
        let retrieved = URLSessionDelegateRegistry.shared.getMostRecentDelegate()
        XCTAssertNotNil(retrieved)
        XCTAssertTrue(retrieved === delegate)
    }
    
    // MARK: - Integration Test
    
    func testAuthenticationChallenge_isForwarded() {
        // Given
        let expectation = XCTestExpectation(description: "Authentication challenge forwarded")
        testDelegate.onAuthChallenge = { challenge in
            expectation.fulfill()
            return (.performDefaultHandling, nil)
        }
        
        // Create and register the delegate
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: testDelegate, delegateQueue: nil)
        session.registerDelegateForDebugSwift()
        
        // Verify delegate was registered
        let captured = URLSessionDelegateRegistry.shared.getMostRecentDelegate()
        XCTAssertNotNil(captured)
        
        // When - simulate authentication challenge
        // Note: This is a simplified test. In real usage, CustomHTTPProtocol would forward the challenge
        if let delegate = captured,
           delegate.responds(to: #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:))) {
            // Simulate a challenge
            let protectionSpace = URLProtectionSpace(
                host: "example.com",
                port: 443,
                protocol: "https",
                realm: nil,
                authenticationMethod: NSURLAuthenticationMethodServerTrust
            )
            let challenge = URLAuthenticationChallenge(
                protectionSpace: protectionSpace,
                proposedCredential: nil,
                previousFailureCount: 0,
                failureResponse: nil,
                error: nil,
                sender: MockAuthenticationChallengeSender()
            )
            
            delegate.urlSession?(session, didReceive: challenge) { disposition, credential in
                // Completion handler called
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Classes

private class MockURLSessionDelegate: NSObject, URLSessionDelegate {
    var onAuthChallenge: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let handler = onAuthChallenge {
            let result = handler(challenge)
            completionHandler(result.0, result.1)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

private class MockAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {}
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {}
}
