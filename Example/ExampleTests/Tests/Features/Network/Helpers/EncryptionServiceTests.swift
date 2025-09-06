//
//  EncryptionServiceTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 06/09/25.
//

import XCTest
import CryptoKit
@testable import DebugSwift

final class EncryptionServiceTests: XCTestCase {
    
    private var encryptionService: EncryptionService!
    
    override func setUp() {
        super.setUp()
        encryptionService = EncryptionService.shared
    }
    
    override func tearDown() {
        super.tearDown()
        encryptionService = nil
    }
    
    // MARK: - Encryption Detection Tests
    
    func testIsEncrypted_withPlainJSON_returnsFalse() {
        // Given
        let jsonString = """
        {
            "user": "john",
            "email": "john@example.com",
            "data": [1, 2, 3, 4]
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let result = encryptionService.isEncrypted(jsonData)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testIsEncrypted_withHighEntropyData_returnsTrue() {
        // Given - Generate random bytes (high entropy)
        let randomData = Data((0..<1024).map { _ in UInt8.random(in: 0...255) })
        
        // When
        let result = encryptionService.isEncrypted(randomData)
        
        // Then
        XCTAssertTrue(result)
    }
    
    // MARK: - Key Registration Tests
    
    func testRegisterDecryptionKey_storesKeyCorrectly() {
        // Given
        let urlPattern = "api.example.com"
        let key = "test-key-32-bytes-for-aes-encry".data(using: .utf8)!
        
        // When
        encryptionService.registerDecryptionKey(for: urlPattern, key: key)
        
        // Then
        let testUrl = URL(string: "https://api.example.com/users")!
        let retrievedKey = encryptionService.getDecryptionKey(for: testUrl)
        XCTAssertEqual(retrievedKey, key)
    }
    
    func testGetDecryptionKey_withNilURL_returnsNil() {
        // Given
        let urlPattern = "api.example.com"
        let key = "test-key-32-bytes-for-aes-encry".data(using: .utf8)!
        encryptionService.registerDecryptionKey(for: urlPattern, key: key)
        
        // When
        let result = encryptionService.getDecryptionKey(for: nil)
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - AES Decryption Tests
    
    func testDecrypt_withNilKey_returnsNil() {
        // Given
        let testData = Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
        
        // When
        let result = encryptionService.decrypt(testData, using: nil)
        
        // Then
        XCTAssertNil(result)
    }
}