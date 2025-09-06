//
//  NetworkViewControllerEncryptionTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 06/09/25.
//

import XCTest
import UIKit
@testable import DebugSwift

final class NetworkViewControllerEncryptionTests: XCTestCase {
    
    private var networkController: NetworkViewController!
    
    override func setUp() {
        super.setUp()
        networkController = NetworkViewController()
        // Reset encryption settings
        DebugSwift.Network.shared.setDecryptionEnabled(false)
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up
        DebugSwift.Network.shared.setDecryptionEnabled(false)
        networkController = nil
    }
    
    // MARK: - Encryption Toggle Button Tests
    
    func testToggleEncryptionDecryption_enablesDecryption() {
        // Given
        XCTAssertFalse(DebugSwift.Network.shared.isDecryptionEnabled)
        
        // When
        networkController.toggleEncryptionDecryption()
        
        // Then
        XCTAssertTrue(DebugSwift.Network.shared.isDecryptionEnabled)
    }
    
    func testToggleEncryptionDecryption_disablesDecryption() {
        // Given
        DebugSwift.Network.shared.setDecryptionEnabled(true)
        XCTAssertTrue(DebugSwift.Network.shared.isDecryptionEnabled)
        
        // When
        networkController.toggleEncryptionDecryption()
        
        // Then
        XCTAssertFalse(DebugSwift.Network.shared.isDecryptionEnabled)
    }
}

// MARK: - NetworkViewControllerDetail Encryption Tests

final class NetworkViewControllerDetailEncryptionTests: XCTestCase {
    
    private var detailController: NetworkViewControllerDetail!
    private var httpModel: HttpModel!
    
    override func setUp() {
        super.setUp()
        httpModel = HttpModel()
        httpModel.url = URL(string: "https://api.example.com/test")!
        httpModel.method = "GET"
        httpModel.statusCode = "200"
        
        detailController = NetworkViewControllerDetail(model: httpModel)
    }
    
    override func tearDown() {
        super.tearDown()
        detailController = nil
        httpModel = nil
    }
    
    // MARK: - Config Generation Tests
    
    func testConfigInit_withUnencryptedModel_showsOnlyRawResponse() {
        // Given
        httpModel.responseData = "{\"message\": \"success\"}".data(using: .utf8)!
        httpModel.isEncrypted = false
        httpModel.decryptedResponseData = nil
        
        // When
        let configs = [NetworkViewControllerDetail.Config](model: httpModel)
        
        // Then
        let responseTitles = configs.compactMap { config in
            config.title.contains("RESPONSE") ? config.title : nil
        }
        
        XCTAssertTrue(responseTitles.contains("RESPONSE (RAW)"))
        XCTAssertFalse(responseTitles.contains("RESPONSE (DECRYPTED)"))
        
        let encryptionStatus = configs.first { $0.title == "ENCRYPTION STATUS" }
        XCTAssertNil(encryptionStatus)
    }
    
    func testConfigInit_withEncryptedModelAndDecryption_showsBothResponses() {
        // Given
        httpModel.responseData = Data([0xFF, 0xEE, 0xDD, 0xCC]) // Mock encrypted
        httpModel.decryptedResponseData = "{\"message\": \"decrypted success\"}".data(using: .utf8)!
        httpModel.isEncrypted = true
        
        // When
        let configs = [NetworkViewControllerDetail.Config](model: httpModel)
        
        // Then
        let responseTitles = configs.compactMap { config in
            config.title.contains("RESPONSE") ? config.title : nil
        }
        
        XCTAssertTrue(responseTitles.contains("RESPONSE (RAW)"))
        XCTAssertTrue(responseTitles.contains("RESPONSE (DECRYPTED)"))
        
        let encryptionStatus = configs.first { $0.title == "ENCRYPTION STATUS" }
        XCTAssertNotNil(encryptionStatus)
        XCTAssertEqual(encryptionStatus?.description, "🔓 Response was encrypted and successfully decrypted")
    }
}