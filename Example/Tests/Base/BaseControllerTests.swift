//
//  BaseControllerTests.swift
//  LaunchTimeTrackerTests
//
//  Created by Matheus Gois on 27/12/2024.
//

import XCTest
@testable import DebugSwift

class BaseControllerTests: XCTestCase {

    func testInit() {
        // Given
        let controller = BaseController()

        // Then
        XCTAssertNotNil(controller)
        if #available(iOS 13.0, *) {
            XCTAssertEqual(controller.overrideUserInterfaceStyle, Theme.shared.interfaceStyleColor)
        }
    }

    func testInitWithNib() {
        // Given
        let controller = BaseController(withNib: true)

        // Then
        XCTAssertNotNil(controller)
        if #available(iOS 13.0, *) {
            XCTAssertEqual(controller.overrideUserInterfaceStyle, Theme.shared.interfaceStyleColor)
        }
    }

    func testViewWillAppear() {
        // Given
        let controller = BaseController()
        let navigationController = UINavigationController(rootViewController: controller)

        // When
        controller.viewWillAppear(true)

        // Then
        XCTAssertTrue(navigationController.navigationBar.prefersLargeTitles)
    }
}
