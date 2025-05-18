//
//  BaseTableControllerTests.swift
//  DebugSwiftTests
//
//  Created by Matheus Gois on 27/12/2024.
//

@testable import DebugSwift
import XCTest

class BaseTableControllerTests: XCTestCase {
    func testInitWithDefaultStyle() {
        // Given
        let controller = BaseTableController()

        // Then
        XCTAssertEqual(controller.tableView.style, .grouped)
    }

    func testInitWithCustomStyle() {
        // Given
        let controller = BaseTableController(style: .plain)

        // Then
        XCTAssertEqual(controller.tableView.style, .plain)
    }

    func testViewWillAppearSetsLargeTitles() {
        // Given
        let controller = BaseTableController()
        let navigationController = UINavigationController(rootViewController: controller)

        // When
        controller.viewWillAppear(false)

        // Then
        XCTAssertTrue(navigationController.navigationBar.prefersLargeTitles)
    }

    func testConfigureAppearanceSetsInterfaceStyle() {
        // Given
        let controller = BaseTableController()
        let expectedStyle = .dark

        // When
        controller.configureAppearance()

        // Then
        if #available(iOS 13.0, *) {
            XCTAssertEqual(controller.overrideUserInterfaceStyle, expectedStyle)
        }
    }
}
