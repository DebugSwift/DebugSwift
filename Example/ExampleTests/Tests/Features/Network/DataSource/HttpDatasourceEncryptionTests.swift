//
//  HttpDatasourceEncryptionTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 06/09/25.
//

import XCTest
@testable import DebugSwift

// MARK: - Mock Classes for Testing

class MockEncryptionService: EncryptionServiceProtocol {
    var shouldDetectAsEncrypted = true
    var shouldReturnDecryptedData = false
    var shouldReturnCustomDecryption = false
    var registeredKeys: [String: Data] = [:]
    var registeredDecryptors: [String: (Data) -> Data?] = [:]
    
    func decrypt(_ data: Data, using key: Data?) -> Data? {
        guard shouldReturnDecryptedData, let key = key, !key.isEmpty else { return nil }
        return "mock-decrypted".data(using: .utf8)
    }
    
    func isEncrypted(_ data: Data) -> Bool {
        return shouldDetectAsEncrypted && data.count > 10 && data.first == 0xFF
    }
    
    func getDecryptionKey(for url: URL?) -> Data? {
        guard let url = url else { return nil }
        let urlString = url.absoluteString.lowercased()
        
        for (pattern, key) in registeredKeys {
            if urlString.contains(pattern.lowercased()) {
                return key
            }
        }
        return nil
    }
    
    func registerDecryptionKey(for urlPattern: String, key: Data) {
        registeredKeys[urlPattern] = key
    }
    
    func registerCustomDecryptor(for urlPattern: String, decryptor: @escaping (Data) -> Data?) {
        registeredDecryptors[urlPattern] = decryptor
    }
    
    func customDecrypt(_ data: Data, for url: URL?) -> Data? {
        guard shouldReturnCustomDecryption, let url = url else { return nil }
        let urlString = url.absoluteString.lowercased()
        
        for (pattern, decryptor) in registeredDecryptors {
            if urlString.contains(pattern.lowercased()) {
                return decryptor(data)
            }
        }
        return nil
    }
}

final class HttpDatasourceEncryptionTests: XCTestCase {

    private final let httpDataSource = HttpDatasource.shared

    // MARK: - Encryption/Decryption Tests
    
    func testAddHttpRequest_withDecryptionDisabled_doesNotDecrypt() {
        // Given
        DebugSwift.Network.shared.setDecryptionEnabled(false)
        let httpModel = HttpModel()
        httpModel.url = URL(string: "https://api.example.com/data")!
        httpModel.responseData = Data([0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA]) // Mock encrypted data
        
        // When
        let result = httpDataSource.addHttpRequest(httpModel)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertFalse(httpModel.isEncrypted)
        XCTAssertNil(httpModel.decryptedResponseData)
    }
    
    func testAddHttpRequest_withDecryptionEnabled_detectsEncryptedData() {
        // Given
        DebugSwift.Network.shared.setDecryptionEnabled(true)
        let mockEncryptionService = MockEncryptionService()
        DebugSwift.Network.shared.setEncryptionService(mockEncryptionService)
        
        let httpModel = HttpModel()
        httpModel.url = URL(string: "https://api.example.com/encrypted")!
        httpModel.responseData = Data([0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, 0x99, 0x88, 0x77, 0x66, 0x55]) // Mock encrypted data
        
        // When
        let result = httpDataSource.addHttpRequest(httpModel)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(httpModel.isEncrypted)
    }
    
    func testAddHttpRequest_withCustomDecryptor_usesCustomDecryption() {
        // Given
        DebugSwift.Network.shared.setDecryptionEnabled(true)
        let mockEncryptionService = MockEncryptionService()
        mockEncryptionService.shouldReturnCustomDecryption = true
        DebugSwift.Network.shared.setEncryptionService(mockEncryptionService)
        
        DebugSwift.Network.shared.registerCustomDecryptor(for: "custom.api.com") { _ in
            return "custom-decrypted-data".data(using: .utf8)
        }
        
        let httpModel = HttpModel()
        httpModel.url = URL(string: "https://custom.api.com/secure")!
        httpModel.responseData = Data([0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, 0x99, 0x88, 0x77, 0x66, 0x55])
        
        // When
        let result = httpDataSource.addHttpRequest(httpModel)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(httpModel.isEncrypted)
        XCTAssertNotNil(httpModel.decryptedResponseData)
        XCTAssertEqual(httpModel.decryptedResponseData, "custom-decrypted-data".data(using: .utf8))
    }
    
    func testAddHttpRequest_withNilResponseData_handlesGracefully() {
        // Given
        DebugSwift.Network.shared.setDecryptionEnabled(true)
        let httpModel = HttpModel()
        httpModel.url = URL(string: "https://api.example.com/empty")!
        httpModel.responseData = nil
        
        // When
        let result = httpDataSource.addHttpRequest(httpModel)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertFalse(httpModel.isEncrypted)
        XCTAssertNil(httpModel.decryptedResponseData)
    }
    
    // MARK: - URL Filtering Tests
    
    func testAddHttpRequest_withIgnoredURLsLiteralSubstring_filtersOutRequest() {
        // Given
        DebugSwift.Network.shared.ignoredURLs = ["analytics.com"]
        let httpModel = makeHttpModel(url: "https://track.analytics.com/event")
        
        // When
        let result = httpDataSource.addHttpRequest(httpModel)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testAddHttpRequest_withOnlyURLsLiteralSubstring_keepsBackwardCompatibleMatching() {
        // Given
        DebugSwift.Network.shared.onlyURLs = ["api.myapp.com"]
        let matchingModel = makeHttpModel(url: "https://staging.api.myapp.com/v1/profile")
        let nonMatchingModel = makeHttpModel(url: "https://analytics.myapp.com/v1/profile")
        
        // When
        let matchingResult = httpDataSource.addHttpRequest(matchingModel)
        let nonMatchingResult = httpDataSource.addHttpRequest(nonMatchingModel)
        
        // Then
        XCTAssertTrue(matchingResult)
        XCTAssertFalse(nonMatchingResult)
    }
    
    func testAddHttpRequest_withIgnoredURLsWildcard_filtersMatchingURL() {
        // Given
        DebugSwift.Network.shared.ignoredURLs = ["https://*.example.com/*"]
        let matchingModel = makeHttpModel(url: "https://api.example.com/v1/orders")
        let nonMatchingModel = makeHttpModel(url: "https://api.another.com/v1/orders")
        
        // When
        let matchingResult = httpDataSource.addHttpRequest(matchingModel)
        let nonMatchingResult = httpDataSource.addHttpRequest(nonMatchingModel)
        
        // Then
        XCTAssertFalse(matchingResult)
        XCTAssertTrue(nonMatchingResult)
    }
    
    func testAddHttpRequest_withOnlyURLsWildcard_allowsOnlyMatchingURL() {
        // Given
        DebugSwift.Network.shared.onlyURLs = ["https://api.example.com/v1/orders/*"]
        let matchingModel = makeHttpModel(url: "https://api.example.com/v1/orders/123")
        let nonMatchingModel = makeHttpModel(url: "https://api.example.com/v1/users/123")
        
        // When
        let matchingResult = httpDataSource.addHttpRequest(matchingModel)
        let nonMatchingResult = httpDataSource.addHttpRequest(nonMatchingModel)
        
        // Then
        XCTAssertTrue(matchingResult)
        XCTAssertFalse(nonMatchingResult)
    }
    
    func testAddHttpRequest_withOnlyURLsQuestionMarkWildcard_allowsSingleCharacterMatch() {
        // Given
        DebugSwift.Network.shared.onlyURLs = ["https://api?.example.com/v1/orders/*"]
        let matchingModel = makeHttpModel(url: "https://api1.example.com/v1/orders/123")
        let nonMatchingModel = makeHttpModel(url: "https://api12.example.com/v1/orders/123")
        
        // When
        let matchingResult = httpDataSource.addHttpRequest(matchingModel)
        let nonMatchingResult = httpDataSource.addHttpRequest(nonMatchingModel)
        
        // Then
        XCTAssertTrue(matchingResult)
        XCTAssertFalse(nonMatchingResult)
    }
    
    func testAddHttpRequest_withWildcardPattern_isCaseInsensitive() {
        // Given
        DebugSwift.Network.shared.ignoredURLs = ["HTTPS://API.EXAMPLE.COM/V1/*"]
        let httpModel = makeHttpModel(url: "https://api.example.com/v1/orders")
        
        // When
        let result = httpDataSource.addHttpRequest(httpModel)
        
        // Then
        XCTAssertFalse(result)
    }
    
    private func makeHttpModel(url: String) -> HttpModel {
        let model = HttpModel()
        model.url = URL(string: url)!
        return model
    }
    
    override func tearDown() {
        super.tearDown()
        // Reset encryption settings
        DebugSwift.Network.shared.setDecryptionEnabled(false)
        DebugSwift.Network.shared.setEncryptionService(EncryptionService.shared)
        DebugSwift.Network.shared.ignoredURLs = []
        DebugSwift.Network.shared.onlyURLs = []
        httpDataSource.removeAll()
    }
}
