//
//  UIImage+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UIImageTests: XCTestCase {

    func testNamedWithValidSystemName() {
        // Given
        let imageName = "star"

        // When
        let image = UIImage.named(imageName)

        // Then
        XCTAssertNotNil(image, "The image should not be nil for a valid system name")
    }

    func testNamedWithInvalidSystemName() {
        // Given
        let imageName = "invalid_name"

        // When
        let image = UIImage.named(imageName)

        // Then
        XCTAssertNil(image, "The image should be nil for an invalid system name")
    }

    func testNamedWithDefaultImage() {
        // Given
        let imageName = "checkmark.circle"
        let defaultImageName = "Circle"

        // When
        let image = UIImage.named(imageName, default: defaultImageName)

        // Then
        XCTAssertNotNil(image, "The image should not be nil when a default image is provided")
    }

    @available(iOS 13.0, *)
    func testOutlineWithValidImage() {
        // Given
        let image = UIImage(systemName: "star")

        // When
        let outlinedImage = image?.outline()

        // Then
        XCTAssertNotNil(outlinedImage, "The outlined image should not be nil for a valid image")
    }

    func testOutlineWithNilImage() {
        // Given
        let image: UIImage? = nil

        // When
        let outlinedImage = image?.outline()

        // Then
        XCTAssertNil(outlinedImage, "The outlined image should be nil for a nil image")
    }
}
