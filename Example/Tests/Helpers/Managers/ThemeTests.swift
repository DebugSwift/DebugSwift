//
//  ThemeTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class ThemeTests: XCTestCase {

    @available(iOS 13.0, *)
    func testBackgroundColorForDarkAppearance() {
        // Given
        let theme = Theme.shared
        Theme.isDarkMode = true

        // with
        let backgroundColor = theme.backgroundColor
        let uiTraitWithInterfaceStyle = UITraitCollection(userInterfaceStyle: .dark)

        // Then
        XCTAssertEqual(backgroundColor.resolvedColor(with: uiTraitWithInterfaceStyle), UIColor.black, "Background Color should resolve to black in dark mode")
    }

    @available(iOS 13.0, *)
    func testBackgroundColorForLightAppearance() {
        // Given
        let theme = Theme.shared
        Theme.isDarkMode = false

        // with
        let backgroundColor = theme.backgroundColor
        let uiTraitWithInterfaceStyle = UITraitCollection(userInterfaceStyle: .light)

        // Then
        XCTAssertEqual(backgroundColor.resolvedColor(with: uiTraitWithInterfaceStyle), UIColor.white, "Background Color should resolve to white in light mode")
    }

    @available(iOS 13.0, *)
    func testFontColorForDarkAppearance() {
        // Given
        let theme = Theme.shared
        Theme.isDarkMode = true

        // with
        let backgroundColor = theme.fontColor
        let uiTraitWithInterfaceStyle = UITraitCollection(userInterfaceStyle: .dark)

        // Then
        XCTAssertEqual(backgroundColor.resolvedColor(with: uiTraitWithInterfaceStyle), UIColor.white, "Font Color should resolve to white in dark mode")
    }

    @available(iOS 13.0, *)
    func testFontColorForLightAppearance() {
        // Given
        let theme = Theme.shared
        Theme.isDarkMode = false

        // with
        let backgroundColor = theme.fontColor
        let uiTraitWithInterfaceStyle = UITraitCollection(userInterfaceStyle: .light)

        // Then
        XCTAssertEqual(backgroundColor.resolvedColor(with: uiTraitWithInterfaceStyle), UIColor.black, "Font Color should resolve to black in light mode")
    }

    @available(iOS 13.0, *)
    func testStatusFetchColorForDarkAppearance() {
        // Given
        let theme = Theme.shared
        Theme.isDarkMode = true

        // with
        let backgroundColor = theme.statusFetchColor
        let uiTraitWithInterfaceStyle = UITraitCollection(userInterfaceStyle: .dark)

        // Then
        XCTAssertEqual(backgroundColor.resolvedColor(with: uiTraitWithInterfaceStyle), UIColor.green, "The status fetch color for dark appearance should be green")
    }

    @available(iOS 13.0, *)
    func testStatusFetchColorForLightAppearance() {
        // Given
        let theme = Theme.shared
        Theme.isDarkMode = false

        // with
        let backgroundColor = theme.statusFetchColor
        let uiTraitWithInterfaceStyle = UITraitCollection(userInterfaceStyle: .light)

        // Then
        XCTAssertEqual(backgroundColor.resolvedColor(with: uiTraitWithInterfaceStyle), UIColor(hexString: "#32CD32"), "The status fetch color for light appearance should be light green")
    }
}
