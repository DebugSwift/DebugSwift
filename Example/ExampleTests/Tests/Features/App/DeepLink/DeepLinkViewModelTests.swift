//
//  DeepLinkViewModelTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class DeepLinkViewModelTests: XCTestCase {

    var sut: DeepLinkViewModel!

    override func setUp() {
        super.setUp()
        sut = DeepLinkViewModel()
        sut.clearHistory()
    }

    override func tearDown() {
        sut.clearHistory()
        sut = nil
        super.tearDown()
    }

    // MARK: - validateURL Tests

    func testValidateURL_emptyString_returnsInvalid() {
        // Given
        let url = ""

        // When
        let result = sut.validateURL(url)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.error)
    }

    func testValidateURL_whitespaceOnly_returnsInvalid() {
        // Given
        let url = "   "

        // When
        let result = sut.validateURL(url)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.error, "URL cannot be empty")
    }

    func testValidateURL_validHTTPSURL_returnsValid() {
        // Given
        let url = "https://www.apple.com"

        // When
        let result = sut.validateURL(url)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.error)
    }

    func testValidateURL_validCustomScheme_returnsValid() {
        // Given
        let url = "debugswift://test"

        // When
        let result = sut.validateURL(url)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.error)
    }

    func testValidateURL_validHTTPURL_returnsValid() {
        // Given
        let url = "http://example.com/path"

        // When
        let result = sut.validateURL(url)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.error)
    }

    // MARK: - detectLinkType Tests

    func testDetectLinkType_httpScheme_returnsUniversalLink() {
        // Given
        let url = URL(string: "http://example.com")!

        // When
        let type = sut.detectLinkType(url)

        // Then
        XCTAssertEqual(type, .universalLink)
    }

    func testDetectLinkType_httpsScheme_returnsUniversalLink() {
        // Given
        let url = URL(string: "https://www.apple.com")!

        // When
        let type = sut.detectLinkType(url)

        // Then
        XCTAssertEqual(type, .universalLink)
    }

    func testDetectLinkType_customScheme_returnsURLScheme() {
        // Given
        let url = URL(string: "debugswift://settings")!

        // When
        let type = sut.detectLinkType(url)

        // Then
        XCTAssertEqual(type, .urlScheme)
    }

    func testDetectLinkType_anotherCustomScheme_returnsURLScheme() {
        // Given
        let url = URL(string: "myapp://profile/123")!

        // When
        let type = sut.detectLinkType(url)

        // Then
        XCTAssertEqual(type, .urlScheme)
    }

    // MARK: - getQuickTestURLs Tests

    func testGetQuickTestURLs_returnsNonEmptyList() {
        // When
        let urls = sut.getQuickTestURLs()

        // Then
        XCTAssertFalse(urls.isEmpty)
    }

    func testGetQuickTestURLs_allEntriesAreNonEmpty() {
        // When
        let urls = sut.getQuickTestURLs()

        // Then
        for url in urls {
            XCTAssertFalse(url.isEmpty)
        }
    }

    func testGetQuickTestURLs_containsExpectedEntries() {
        // When
        let urls = sut.getQuickTestURLs()

        // Then
        XCTAssertTrue(urls.contains("debugswift://profile/123"))
        XCTAssertTrue(urls.contains("https://github.com/DebugSwift/DebugSwift"))
    }

    // MARK: - clearHistory Tests

    func testClearHistory_onAlreadyEmptyHistory_remainsEmpty() {
        // Given
        XCTAssertTrue(sut.history.isEmpty)

        // When
        sut.clearHistory()

        // Then
        XCTAssertTrue(sut.history.isEmpty)
    }

    func testClearHistory_invokesOnHistoryUpdatedCallback() {
        // Given
        var callbackInvoked = false
        sut.onHistoryUpdated = { callbackInvoked = true }

        // When
        sut.clearHistory()

        // Then
        XCTAssertTrue(callbackInvoked)
    }

    // MARK: - deleteEntry Tests

    func testDeleteEntry_outOfBoundsIndex_doesNotCrash() {
        // Given — history is empty
        XCTAssertTrue(sut.history.isEmpty)

        // When / Then — should not crash
        sut.deleteEntry(at: 99)
        XCTAssertTrue(sut.history.isEmpty)
    }

    func testDeleteEntry_outOfBoundsIndex_doesNotInvokeCallback() {
        // Given
        var callbackInvoked = false
        sut.onHistoryUpdated = { callbackInvoked = true }

        // When
        sut.deleteEntry(at: 0)

        // Then — guard should have returned early without calling the callback
        XCTAssertFalse(callbackInvoked)
    }
}

// MARK: - DeepLinkType Equatable conformance for tests

extension DeepLinkType {
    static func == (lhs: DeepLinkType, rhs: DeepLinkType) -> Bool {
        switch (lhs, rhs) {
        case (.urlScheme, .urlScheme), (.universalLink, .universalLink):
            return true
        default:
            return false
        }
    }
}
