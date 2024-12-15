//
//  String+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class StringTests: XCTestCase {

    func testImageWithValidAttributesAndSize() {
        // Given
        let string = "Test"
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
        let size = CGSize(width: 100, height: 50)

        // When
        let image = string.image(with: attributes, size: size)

        // Then
        XCTAssertNotNil(image, "The image should not be nil")
    }

    func testImageWithDefaultAttributesAndSize() {
        // Given
        let string = "Test"

        // When
        let image = string.image()

        // Then
        XCTAssertNotNil(image, "The image should not be nil")
    }

    func testImageWithEmptyString() {
        // Given
        let string = ""

        // When
        let image = string.image()

        // Then
        XCTAssertNil(image, "The image should be nil for an empty string")
    }

    func testLeftPaddingWithValidLength() {
        // Given
        let string = "Test"
        let length = 10
        let pad = "-"

        // When
        let paddedString = string.leftPadding(toLength: length, withPad: pad)

        // Then
        XCTAssertEqual(paddedString, "------Test", "The padded string should be '------Test'")
    }

    func testLeftPaddingWithDefaultPad() {
        // Given
        let string = "Test"
        let length = 10

        // When
        let paddedString = string.leftPadding(toLength: length)

        // Then
        XCTAssertEqual(paddedString, "      Test", "The padded string should be '      Test'")
    }

    func testLeftPaddingWithShorterLength() {
        // Given
        let string = "Test"
        let length = 2

        // When
        let paddedString = string.leftPadding(toLength: length)

        // Then
        XCTAssertEqual(paddedString, "Test", "The padded string should be 'Test'")
    }
}
