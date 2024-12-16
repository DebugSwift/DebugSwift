//
//  ThemeTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class ThemeTests: XCTestCase {

    func testInterfaceStyleColorForDarkAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .dark

        // When
        let interfaceStyleColor = theme.interfaceStyleColor

        // Then
        XCTAssertEqual(interfaceStyleColor, .dark, "The interface style color for dark appearance should be .dark")
    }

    func testInterfaceStyleColorForLightAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .light

        // When
        let interfaceStyleColor = theme.interfaceStyleColor

        // Then
        XCTAssertEqual(interfaceStyleColor, .light, "The interface style color for light appearance should be .light")
    }

    @available(iOS 13.0, *)
    func testInterfaceStyleColorForAutomaticAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .automatic

        // When
        let interfaceStyleColor = theme.interfaceStyleColor

        // Then
        XCTAssertEqual(interfaceStyleColor, .unspecified, "The interface style color for automatic appearance should be .unspecified")
    }

    func testBackgroundColorForDarkAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .dark

        // When
        let backgroundColor = theme.backgroundColor

        // Then
        XCTAssertEqual(backgroundColor, .black, "The background color for dark appearance should be .black")
    }

    func testBackgroundColorForLightAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .light

        // When
        let backgroundColor = theme.backgroundColor

        // Then
        XCTAssertEqual(backgroundColor, .white, "The background color for light appearance should be .white")
    }

    @available(iOS 13.0, *)
    func testBackgroundColorForAutomaticAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .automatic

        // When
        let backgroundColor = theme.backgroundColor

        // Then
        XCTAssertEqual(backgroundColor, .systemBackground, "The background color for automatic appearance should be .systemBackground")
    }

    func testFontColorForDarkAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .dark

        // When
        let fontColor = theme.fontColor

        // Then
        XCTAssertEqual(fontColor, .white, "The font color for dark appearance should be .white")
    }

    func testFontColorForLightAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .light

        // When
        let fontColor = theme.fontColor

        // Then
        XCTAssertEqual(fontColor, .black, "The font color for light appearance should be .black")
    }

    @available(iOS 13.0, *)
    func testFontColorForAutomaticAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .automatic

        // When
        let fontColor = theme.fontColor

        // Then
        XCTAssertEqual(fontColor, .label, "The font color for automatic appearance should be .label")
    }

    func testStatusFetchColorForDarkAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .dark

        // When
        let statusFetchColor = theme.statusFetchColor

        // Then
        XCTAssertEqual(statusFetchColor, .green, "The status fetch color for dark appearance should be .green")
    }

    func testStatusFetchColorForLightAppearance() {
        // Given
        let theme = Theme.shared
        theme.appearance = .light

        // When
        let statusFetchColor = theme.statusFetchColor

        // Then
        XCTAssertEqual(statusFetchColor, UIColor(hexString: "#32CD32") ?? .green, "The status fetch color for light appearance should be light green")
    }
}
