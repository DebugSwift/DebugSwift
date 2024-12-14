//
//  URLCache+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class URLCacheTests: XCTestCase {

    func testStoreIfNeededWithInvalidExtension() {
        // Given
        let url = URL(string: "https://example.com/file.txt")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Expires": "Wed, 21 Oct 2025 07:28:00 GMT"])!
        let data = Data([0x00, 0x01, 0x02])
        let task = URLSession.shared.dataTask(with: request)
        task.setValue(response, forKey: "response")
        let cache = URLCache.customHttp

        // When
        cache.storeIfNeeded(for: task, data: data)

        // Then
        let cachedResponse = cache.cachedResponse(for: request)
        XCTAssertNil(cachedResponse, "The response should not be cached for unsupported file extensions")
    }

    func testValidCacheWithValidCache() {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Expires": "Wed, 21 Oct 2025 07:28:00 GMT"])!
        let data = Data([0x00, 0x01, 0x02])
        let cache = URLCache.customHttp
        let cachedResponse = CachedURLResponse(response: response, data: data, userInfo: ["Expires": Date().addingTimeInterval(60 * 60)], storagePolicy: .allowed)
        cache.storeCachedResponse(cachedResponse, for: request)

        // When
        let validCache = cache.validCache(for: request)

        // Then
        XCTAssertNotNil(validCache, "The cache should be valid")
        XCTAssertEqual(validCache?.data, data, "The cached data should match the original data")
    }

    func testValidCacheWithExpiredCache() {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Expires": "Wed, 21 Oct 2025 07:28:00 GMT"])!
        let data = Data([0x00, 0x01, 0x02])
        let cache = URLCache.customHttp
        let cachedResponse = CachedURLResponse(response: response, data: data, userInfo: ["Expires": Date().addingTimeInterval(-60 * 60)], storagePolicy: .allowed)
        cache.storeCachedResponse(cachedResponse, for: request)

        // When
        let validCache = cache.validCache(for: request)

        // Then
        XCTAssertNil(validCache, "The cache should be expired and thus invalid")
    }
}
