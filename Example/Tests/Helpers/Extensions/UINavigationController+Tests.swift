//
//  UINavigationController+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UINavigationControllerTests: XCTestCase {

    var navigationController: UINavigationController!
    var tabBar: UITabBar!

    override func setUpWithError() throws {
        try super.setUpWithError()
        navigationController = UINavigationController()
        tabBar = UITabBar()
    }

    override func tearDownWithError() throws {
        navigationController = nil
        tabBar = nil
        try super.tearDownWithError()
    }

    func testSetBackgroundColor_iOS13AndAbove() throws {
        if #available(iOS 13.0, *) {
            // Given
            let color = UIColor.red

            // When
            navigationController.setBackgroundColor(color: color)

            // Then
            XCTAssertEqual(navigationController.navigationBar.standardAppearance.backgroundColor, color)
            XCTAssertEqual(navigationController.navigationBar.scrollEdgeAppearance?.backgroundColor, color)
            XCTAssertEqual(navigationController.navigationBar.compactAppearance?.backgroundColor, color)
        }
    }

    func testSetBackgroundColor_iOSBelow13_ClearColor() throws {
        if #available(iOS 13.0, *) { return }

        // Given
        let color = UIColor.clear

        // When
        navigationController.setBackgroundColor(color: color)

        // Then
        XCTAssertEqual(navigationController.navigationBar.barTintColor, .clear)
        XCTAssertNotNil(navigationController.navigationBar.backgroundImage(for: .default))
        XCTAssertNotNil(navigationController.navigationBar.shadowImage)
        XCTAssertTrue(navigationController.navigationBar.isTranslucent)
    }

    func testSetBackgroundColor_iOSBelow13_NonClearColor() throws {
        if #available(iOS 13.0, *) { return }

        // Given
        let color = UIColor.red

        // When
        navigationController.setBackgroundColor(color: color)

        // Then
        XCTAssertEqual(navigationController.navigationBar.barTintColor, color)
        XCTAssertNil(navigationController.navigationBar.backgroundImage(for: .default))
        XCTAssertNil(navigationController.navigationBar.shadowImage)
        XCTAssertFalse(navigationController.navigationBar.isTranslucent)
    }

    func testSetTabBarBackgroundColor_iOS13AndAbove() throws {
        if #available(iOS 13.0, *) {
            // Given
            let color = UIColor.blue

            // When
            tabBar.setBackgroundColor(color: color)

            // Then
            XCTAssertEqual(tabBar.standardAppearance.backgroundColor, color)
            if #available(iOS 15.0, *) {
                XCTAssertEqual(tabBar.scrollEdgeAppearance?.backgroundColor, color)
            }
        }
    }

    func testSetTabBarBackgroundColor_iOSBelow13() throws {
        if #available(iOS 13.0, *) { return }

        // Given
        let color = UIColor.blue

        // When
        tabBar.setBackgroundColor(color: color)

        // Then
        XCTAssertEqual(tabBar.barTintColor, color)
    }
}
