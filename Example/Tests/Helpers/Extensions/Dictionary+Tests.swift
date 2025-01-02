//
//  Dictionary+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class DictionaryTests: XCTestCase {

    func testFormattedStringWithNonEmptyDictionary() {
        // Given
        let dictionary: [String: Any] = ["key1": "value1", "key2": 2]

        // When
        let formattedString = dictionary.formattedString()

        // Then
        let expectedLines = [
            "key1: value1",
            "key2: 2"
        ]

        let formattedLines = formattedString.split(separator: "\n").map { String($0) }
        for line in expectedLines {
            XCTAssertTrue(formattedLines.contains(line), "Expected line '\(line)' is missing from the formatted string.")
        }
    }

    func testFormattedStringWithEmptyDictionary() {
        // Given
        let dictionary: [String: Any] = [:]

        // When
        let formattedString = dictionary.formattedString()

        // Then
        XCTAssertEqual(formattedString, "", "The formatted string should be empty for an empty dictionary")
    }

    func testConvertKeysToStringWithValidKeys() {
        // Given
        let dictionary: [AnyHashable: Any] = ["key1": "value1", 2: "value2"]

        // When
        let convertedDictionary = dictionary.convertKeysToString()

        // Then
        let expectedDictionary: [String: Any] = ["key1": "value1"]
        XCTAssertEqual(convertedDictionary as NSDictionary, expectedDictionary as NSDictionary, "The converted dictionary should only contain string keys")
    }

    func testConvertKeysToStringWithEmptyDictionary() {
        // Given
        let dictionary: [AnyHashable: Any] = [:]

        // When
        let convertedDictionary = dictionary.convertKeysToString()

        // Then
        XCTAssertTrue(convertedDictionary.isEmpty, "The converted dictionary should be empty for an empty dictionary")
    }

    func testAsJsonStrWithValidDictionary() {
        // Given
        let dictionary: [String: Any] = ["key1": "value1", "key2": 2]

        // When
        let jsonString = dictionary.asJsonStr()

        // Then
        let expectedString = "{\"key1\":\"value1\",\"key2\":2}"
        XCTAssertEqual(jsonString, expectedString, "The JSON string should match the expected output")
    }

    func testAsJsonStrWithEmptyDictionary() {
        // Given
        let dictionary: [String: Any] = [:]

        // When
        let jsonString = dictionary.asJsonStr()

        // Then
        XCTAssertEqual(jsonString, "{}", "The JSON string should be an empty JSON object for an empty dictionary")
    }

    func testAsJsonStrWithInvalidDictionary() {
        // Given
        let dictionary: [String: Any] = ["key1": Data()]

        // When
        let jsonString = dictionary.asJsonStr()

        // Then
        let expected = """
        {"key1":""}
        """.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(jsonString, expected, "The JSON string should be nil for a dictionary with non-serializable values")
    }
}
