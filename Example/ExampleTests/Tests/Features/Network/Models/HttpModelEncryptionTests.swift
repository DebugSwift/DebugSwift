//
//  HttpModelEncryptionTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 06/09/25.
//

import XCTest
@testable import DebugSwift

final class HttpModelEncryptionTests: XCTestCase {
    
    private var httpModel: HttpModel!
    
    override func setUp() {
        super.setUp()
        httpModel = HttpModel()
    }
    
    override func tearDown() {
        super.tearDown()
        httpModel = nil
    }
    
    // MARK: - Property Initialization Tests
    
    func testHttpModel_initialValues_areCorrect() {
        // Then
        XCTAssertNil(httpModel.decryptedResponseData)
        XCTAssertFalse(httpModel.isEncrypted)
    }
    
    // MARK: - Encryption Flag Tests
    
    func testIsEncrypted_defaultValue_isFalse() {
        // When
        let result = httpModel.isEncrypted
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testIsEncrypted_canBeSetToTrue() {
        // When
        httpModel.isEncrypted = true
        
        // Then
        XCTAssertTrue(httpModel.isEncrypted)
    }
    
    // MARK: - Decrypted Response Data Tests
    
    func testDecryptedResponseData_defaultValue_isNil() {
        // When
        let result = httpModel.decryptedResponseData
        
        // Then
        XCTAssertNil(result)
    }
    
    func testDecryptedResponseData_canBeSet() {
        // Given
        let testData = "decrypted content".data(using: .utf8)!
        
        // When
        httpModel.decryptedResponseData = testData
        
        // Then
        XCTAssertEqual(httpModel.decryptedResponseData, testData)
    }
    
    // MARK: - Response Data Coexistence Tests
    
    func testResponseData_andDecryptedResponseData_canCoexist() {
        // Given
        let originalData = "encrypted response".data(using: .utf8)!
        let decryptedData = "decrypted response".data(using: .utf8)!
        
        // When
        httpModel.responseData = originalData
        httpModel.decryptedResponseData = decryptedData
        httpModel.isEncrypted = true
        
        // Then
        XCTAssertEqual(httpModel.responseData, originalData)
        XCTAssertEqual(httpModel.decryptedResponseData, decryptedData)
        XCTAssertTrue(httpModel.isEncrypted)
        XCTAssertNotEqual(httpModel.responseData, httpModel.decryptedResponseData)
    }
}