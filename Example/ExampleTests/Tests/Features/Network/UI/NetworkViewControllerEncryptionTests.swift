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
    
    // MARK: - Section Generation Tests
    
    func testSectionBuild_withUnencryptedModel_showsOnlyRawResponse() {
        // Given
        httpModel.responseData = "{\"message\": \"success\"}".data(using: .utf8)!
        httpModel.isEncrypted = false
        httpModel.decryptedResponseData = nil
        
        // When
        let sections = NetworkViewControllerDetail.DetailSection.buildSections(from: httpModel)
        
        // Then
        let responseSection = sections.first { $0.title == "RESPONSE" }
        XCTAssertNotNil(responseSection)
        
        let responseTitles = responseSection?.items.map { $0.title } ?? []
        XCTAssertTrue(responseTitles.contains("Raw Response"))
        XCTAssertTrue(responseTitles.contains("Browse Response Body"))
        
        // Check no encryption status in additional info
        let additionalSection = sections.first { $0.title == "ADDITIONAL INFO" }
        let encryptionItem = additionalSection?.items.first { $0.title == "ENCRYPTION" }
        XCTAssertNil(encryptionItem)
    }
    
    func testSectionBuild_withEncryptedModelAndDecryption_showsEncryptionStatus() {
        // Given
        httpModel.responseData = Data([0xFF, 0xEE, 0xDD, 0xCC]) // Mock encrypted
        httpModel.decryptedResponseData = "{\"message\": \"decrypted success\"}".data(using: .utf8)!
        httpModel.isEncrypted = true
        
        // When
        let sections = NetworkViewControllerDetail.DetailSection.buildSections(from: httpModel)
        
        // Then
        let responseSection = sections.first { $0.title == "RESPONSE" }
        XCTAssertNotNil(responseSection, "Response section should exist")
        
        let responseTitles = responseSection?.items.map { $0.title } ?? []
        // Check that browse response body exists
        XCTAssertTrue(responseTitles.contains("Browse Response Body"), "Should contain Browse Response Body")
        // Check that raw response exists (with or without decrypted label)
        let hasRawResponse = responseTitles.contains { $0.contains("Raw Response") }
        XCTAssertTrue(hasRawResponse, "Should contain Raw Response. Found: \(responseTitles)")
        
        // Check encryption status in additional info
        let additionalSection = sections.first { $0.title == "ADDITIONAL INFO" }
        let encryptionItem = additionalSection?.items.first { $0.title == "ENCRYPTION" }
        XCTAssertNotNil(encryptionItem)
        XCTAssertEqual(encryptionItem?.value, "🔓 Encrypted and decrypted")
    }
}