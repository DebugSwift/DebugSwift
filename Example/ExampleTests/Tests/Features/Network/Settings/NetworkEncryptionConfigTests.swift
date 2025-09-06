//
//  NetworkEncryptionConfigTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 06/09/25.
//

import XCTest
@testable import DebugSwift

final class NetworkEncryptionConfigTests: XCTestCase {
    
    private var networkConfig: DebugSwift.Network!
    
    override func setUp() {
        super.setUp()
        networkConfig = DebugSwift.Network.shared
        // Reset to default state
        networkConfig.setDecryptionEnabled(false)
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up
        networkConfig.setDecryptionEnabled(false)
        networkConfig = nil
    }
    
    // MARK: - Decryption Toggle Tests
    
    func testIsDecryptionEnabled_defaultValue_isFalse() {
        // When
        let result = networkConfig.isDecryptionEnabled
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testSetDecryptionEnabled_enablesDecryption() {
        // When
        networkConfig.setDecryptionEnabled(true)
        
        // Then
        XCTAssertTrue(networkConfig.isDecryptionEnabled)
    }
    
    func testSetDecryptionEnabled_disablesDecryption() {
        // Given
        networkConfig.setDecryptionEnabled(true)
        
        // When
        networkConfig.setDecryptionEnabled(false)
        
        // Then
        XCTAssertFalse(networkConfig.isDecryptionEnabled)
    }
    
    // MARK: - Encryption Service Tests
    
    func testEncryptionService_defaultValue_isEncryptionService() {
        // When
        let service = networkConfig.encryptionService
        
        // Then
        XCTAssertTrue(service is EncryptionService)
    }
}