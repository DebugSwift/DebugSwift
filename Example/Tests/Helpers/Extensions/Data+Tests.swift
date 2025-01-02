//
//  Data+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class DataTests: XCTestCase {

    func testFormattedSize() {
        // Given
        let data = Data(repeating: 0, count: 1024)

        // When
        let formattedSize = data.formattedSize()

        // Then
        XCTAssertEqual(formattedSize, "1 KB", "The formatted size should be 1 KB")
    }

    func testFormattedStringWithValidJSON() {
        // Given
        let jsonString = "{\"key\":\"value\"}"
        let data = jsonString.data(using: .utf8)!

        // When
        let formattedString = data.formattedString()

        // Then
        XCTAssertEqual(formattedString, "{\n  \"key\" : \"value\"\n}", "The formatted string should be pretty printed JSON")
    }

    func testFormattedStringWithInvalidJSON() {
        // Given
        let invalidJSONString = "{key:value}"
        let data = invalidJSONString.data(using: .utf8)!

        // When
        let formattedString = data.formattedString()

        // Then
        XCTAssertEqual(formattedString, invalidJSONString, "The formatted string should be the original string")
    }

    func testFormattedCurlStringWithValidData() {
        // Given
        let jsonString = "{\"key\":\"value\"}"
        let data = jsonString.data(using: .utf8)!

        // When
        let formattedCurlString = data.formattedCurlString()

        // Then
        XCTAssertEqual(formattedCurlString, jsonString.escapedForCurl(), "The formatted curl string should be escaped JSON string")
    }

    func testFormattedCurlStringWithInvalidData() {
        // Given
        let invalidJSONString = "{key:value}"
        let data = invalidJSONString.data(using: .utf8)!

        // When
        let formattedCurlString = data.formattedCurlString()

        // Then
        XCTAssertEqual(formattedCurlString, invalidJSONString.escapedForCurl(), "The formatted curl string should be escaped original string")
    }

    func testStringEscapedForCurl() {
        // Given
        let originalString = "This is a 'test' string"

        // When
        let escapedString = originalString.escapedForCurl()

        // Then
        XCTAssertEqual(escapedString, "This is a \\'test\\' string", "The escaped string should replace single quotes with escaped single quotes")
    }

    func testURLRequestFormattedCurlString() {
        // Given
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBody = "{\"key\":\"value\"}".data(using: .utf8)

        // When
        let curlString = request.formattedCurlString()

        // Then
        let expectedCurlString = """
            curl -X POST -H 'Content-Type: application/json' -d '{"key":"value"}' https://example.com
        """.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(curlString, expectedCurlString, "The formatted curl string should match the expected curl command")
    }
}
