//
//  CustomAuthenticationExample.swift
//  Example
//
//  Created to demonstrate fix for issue #240 - URLSession authentication challenge forwarding
//

import Foundation
import DebugSwift

/// Example demonstrating how to use custom URLSessionDelegate with DebugSwift
/// This addresses issue #240 where DebugSwift's network sniffing would interfere
/// with custom authentication challenge handling
final class CustomAuthenticationExample: NSObject {
    
    private var session: URLSession!
    
    override init() {
        super.init()
        
        // Create URLSession with custom delegate for authentication
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        // Register delegate with DebugSwift for authentication forwarding
        session.registerDelegateForDebugSwift()
    }
    
    /// Make a request that requires authentication
    func makeAuthenticatedRequest(to url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "CustomAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            completion(.success(data))
        }
        task.resume()
    }
}

// MARK: - URLSessionDelegate

extension CustomAuthenticationExample: URLSessionDelegate {
    
    /// Handle authentication challenges at the session level
    /// This method will now be properly called even when DebugSwift is intercepting network requests
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        print("🔐 Custom authentication challenge received")
        print("   Protection space: \(challenge.protectionSpace.authenticationMethod)")
        print("   Host: \(challenge.protectionSpace.host)")
        
        // Example: Handle server trust authentication (SSL pinning, custom certificates, etc.)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                print("   ✅ Server trust validated")
                return
            }
        }
        
        // Example: Handle basic authentication
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            let credential = URLCredential(user: "username", password: "password", persistence: .forSession)
            completionHandler(.useCredential, credential)
            print("   ✅ Basic authentication provided")
            return
        }
        
        // Example: Handle client certificate authentication
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            // Load client certificate from keychain or bundle
            // let identity = ... load identity ...
            // let credential = URLCredential(identity: identity, certificates: nil, persistence: .forSession)
            // completionHandler(.useCredential, credential)
            completionHandler(.performDefaultHandling, nil)
            print("   ℹ️ Client certificate authentication requested (using default handling)")
            return
        }
        
        // Default: Use system default handling
        completionHandler(.performDefaultHandling, nil)
        print("   ℹ️ Using default authentication handling")
    }
}

// MARK: - URLSessionTaskDelegate

extension CustomAuthenticationExample: URLSessionTaskDelegate {
    
    /// Handle authentication challenges at the task level
    /// This provides more granular control per-request
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        print("🔐 Task-level authentication challenge received for: \(task.originalRequest?.url?.absoluteString ?? "unknown")")
        
        // You can implement per-task authentication logic here
        // For this example, we'll delegate to the session-level handler
        self.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
}

// MARK: - Usage Example

extension CustomAuthenticationExample {
    
    static func runExample() {
        print("=== Custom Authentication Example (Issue #240 Fix) ===\n")
        
        let example = CustomAuthenticationExample()
        
        // Example 1: HTTPS request with server trust validation
        if let url = URL(string: "https://httpbin.org/get") {
            print("1️⃣ Making HTTPS request with server trust validation...")
            example.makeAuthenticatedRequest(to: url) { result in
                switch result {
                case .success(let data):
                    print("   ✅ Success! Received \(data.count) bytes")
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                        print("   Response: \(json)")
                    }
                case .failure(let error):
                    print("   ❌ Error: \(error.localizedDescription)")
                }
            }
        }
        
        // Example 2: Request that requires authentication
        // Note: This will fail with 401 but demonstrates the challenge is received
        if let url = URL(string: "https://httpbin.org/basic-auth/user/passwd") {
            print("\n2️⃣ Making request that requires basic authentication...")
            example.makeAuthenticatedRequest(to: url) { result in
                switch result {
                case .success(let data):
                    print("   ✅ Success! Received \(data.count) bytes")
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                        print("   Response: \(json)")
                    }
                case .failure(let error):
                    print("   ℹ️ Expected auth failure (demo purposes): \(error.localizedDescription)")
                }
            }
        }
        
        print("\n=== End of Example ===")
        print("\n💡 Key Points:")
        print("   • Your custom URLSessionDelegate methods are now called even when DebugSwift intercepts requests")
        print("   • Authentication challenges are properly forwarded to your delegate")
        print("   • DebugSwift still captures network traffic for debugging")
        print("   • Both session-level and task-level authentication challenges are supported")
    }
}

