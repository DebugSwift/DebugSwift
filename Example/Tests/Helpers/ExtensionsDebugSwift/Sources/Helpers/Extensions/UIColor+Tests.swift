//
//  UIColor+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UIColorTests: XCTestCase {

    func testInitWithHexStringValid() {
        // Given
        let hexString = "#FF5733"

        // When
        let color = UIColor(hexString: hexString)

        // Then
        XCTAssertNotNil(color, "The color should be created successfully with a valid hex string")
    }

    func testInitWithHexStringInvalid() {
        // Given
        let hexString = "ZZZZZZ"

        // When
        let color = UIColor(hexString: hexString)

        // Then
        XCTAssertNil(color, "The color should be nil with an invalid hex string")
    }

    func testRandomColor() {
        // Given
        // No given state needed

        // When
        let color = UIColor.randomColor()

        // Then
        XCTAssertNotNil(color, "The random color should be created successfully")
    }

    func testInitWithHexAndAlpha() {
        // Given
        let hexString = "#FF5733"
        let alpha: CGFloat = 0.5

        // When
        let color = UIColor(hex: hexString, alpha: alpha)

        // Then
        XCTAssertNotNil(color, "The color should be created successfully with a valid hex string and alpha")
    }

    func testIntFromHexString() {
        // Given
        let hexString = "#FF5733"

        // When
        let hexInt = UIColor.intFromHexString(hex: hexString)

        // Then
        XCTAssertEqual(hexInt, 0xFF5733, "The hex integer should be correctly converted from the hex string")
    }

    func testHexString() {
        // Given
        let color = UIColor(red: 1.0, green: 0.341, blue: 0.2, alpha: 1.0)

        // When
        let hexString = color.hexString

        // Then
        XCTAssertEqual(hexString, "#FF5733", "The hex string should be correctly generated from the color")
    }

    @available(iOS 13.0, *)
    func testInitWithLightAndDarkColors() {
        // Given
        let lightColor = UIColor.white
        let darkColor = UIColor.black

        // When
        let color = UIColor(light: lightColor, dark: darkColor)

        // Then
        XCTAssertNotNil(color, "The color should be created successfully with light and dark colors")
    }
}
