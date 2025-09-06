//
//  EncryptionExample.swift
//  Example
//
//  Created by DebugSwift on 06/09/25.
//

import Foundation
import DebugSwift

class EncryptionExample {
    
    static func setupEncryptionDecryption() {
        // Enable decryption feature
        DebugSwift.Network.shared.setDecryptionEnabled(true)
        
        // Example 1: Register a decryption key for specific API endpoints
        if let key = "your-32-byte-aes-key-here-123456".data(using: .utf8) {
            DebugSwift.Network.shared.registerDecryptionKey(for: "api.example.com/encrypted", key: key)
        }
        
        // Example 2: Register a custom decryptor for more complex scenarios
        DebugSwift.Network.shared.registerCustomDecryptor(for: "api.myapp.com") { encryptedData in
            // Your custom decryption logic here
            // This could involve multiple steps, different algorithms, etc.
            return customDecrypt(encryptedData)
        }
        
        // Example 3: Register decryption for multiple endpoints
        let endpoints = [
            "api.secure.com/data",
            "backend.myapp.com/user",
            "services.example.org/payment"
        ]
        
        if let commonKey = generateAESKey() {
            for endpoint in endpoints {
                DebugSwift.Network.shared.registerDecryptionKey(for: endpoint, key: commonKey)
            }
        }
    }
    
    // Example of generating an AES key (in real apps, keys should come from secure storage)
    private static func generateAESKey() -> Data? {
        // This is just an example - in production, load your actual keys securely
        return "MySecureApp-AES-Key-32bytes!!!".data(using: .utf8)
    }
    
    // Example custom decryption function
    private static func customDecrypt(_ data: Data) -> Data? {
        // Example: Your app might use a custom encryption scheme
        // This could involve:
        // 1. Extracting a header with encryption metadata
        // 2. Using different keys based on the header
        // 3. Applying multiple decryption steps
        // 4. Validating integrity checksums
        
        guard data.count > 16 else { return nil }
        
        // Example: Extract custom header (first 16 bytes)
        let header = data.prefix(16)
        let payload = data.dropFirst(16)
        
        // Based on header, determine decryption method
        if header.starts(with: "MYAPP_V1".data(using: .utf8)!) {
            return decryptV1Format(payload)
        } else if header.starts(with: "MYAPP_V2".data(using: .utf8)!) {
            return decryptV2Format(payload)
        }
        
        return nil
    }
    
    private static func decryptV1Format(_ data: Data) -> Data? {
        // Your V1 decryption logic
        return data // Placeholder
    }
    
    private static func decryptV2Format(_ data: Data) -> Data? {
        // Your V2 decryption logic
        return data // Placeholder
    }
}

// Usage in your app delegate or main app setup:
/*
 override func viewDidLoad() {
     super.viewDidLoad()
     
     // Setup encryption/decryption for debugging
     EncryptionExample.setupEncryptionDecryption()
     
     // Your regular app setup...
 }
 */