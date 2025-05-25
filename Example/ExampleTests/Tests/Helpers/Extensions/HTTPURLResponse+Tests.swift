//
//  HTTPURLResponse+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class HTTPURLResponseTests: XCTestCase {

    func testExpiresWithCacheControlMaxAge() {
        // Given
        let headers = ["Cache-Control": "max-age=60"]
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: headers)!

        // When
        let expiresDate = response.expires()

        // Then
        XCTAssertNotNil(expiresDate)
        XCTAssertEqual(expiresDate!.timeIntervalSinceNow, TimeInterval(60), accuracy: 1)
    }

    func testExpiresWithCacheControlMaxAgeAndOtherDirectives() {
        // Given
        let headers = ["Cache-Control": "max-age=120, must-revalidate"]
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: headers)!

        // When
        let expiresDate = response.expires()

        // Then
        XCTAssertNotNil(expiresDate)
        XCTAssertEqual(expiresDate!.timeIntervalSinceNow, TimeInterval(120), accuracy: 1)
    }

    func testExpiresWithExpiresHeader() {
        // Given
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let dateFormatter = Date.dateFormatter
        let headers = ["Expires": dateFormatter.string(from: futureDate)]
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: headers)!

        // When
        let expiresDate = response.expires()

        // Then
        XCTAssertNotNil(expiresDate)
        XCTAssertEqual(expiresDate!.timeIntervalSinceReferenceDate, futureDate.timeIntervalSinceReferenceDate, accuracy: 1)
    }

    func testExpiresWithInvalidCacheControl() {
        // Given
        let headers = ["Cache-Control": "invalid-directive"]
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: headers)!

        // When
        let expiresDate = response.expires()

        // Then
        XCTAssertNil(expiresDate)
    }

    func testExpiresWithInvalidExpiresHeader() {
        // Given
        let headers = ["Expires": "invalid-date"]
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: headers)!

        // When
        let expiresDate = response.expires()

        // Then
        XCTAssertNil(expiresDate)
    }

    func testExpiresWithNoCacheHeaders() {
        // Given
        let headers: [String: String] = [:]
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: headers)!

        // When
        let expiresDate = response.expires()

        // Then
        XCTAssertNil(expiresDate)
    }
}
