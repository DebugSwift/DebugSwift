//
//  TabBarControllerTests.swift
//  DebugSwiftTests
//
//  Created by Matheus Gois on 27/12/2024.
//

@testable import DebugSwift
import XCTest

class TabBarControllerTests: XCTestCase {
    private var tabBarController: TabBarController!
    private var window: UIWindow!

    override func setUpWithError() throws {
        // Initialize the TabBarController before each test
        tabBarController = TabBarController()

        // Create a window for the TabBarController to load in
        window = UIWindow()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        tabBarController = nil
        window = nil
    }

    func testTabBarConfiguration() {
        // Test that the TabBar is properly configured.
        XCTAssertNotNil(tabBarController.tabBar)
        XCTAssertEqual(tabBarController.tabBar.tintColor, UIColor.white)
        XCTAssertEqual(tabBarController.tabBar.unselectedItemTintColor, .gray)
    }

    @MainActor
    func testViewControllersAreSet() {
        // Test that the view controllers are set correctly
        let customControllers = DebugSwift.App.shared.customControllers?() ?? []
        let controllers = DebugSwift.App.shared.defaultControllers + customControllers

        XCTAssertEqual(tabBarController.viewControllers?.count, controllers.count)

        // Check that each view controller is wrapped in a UINavigationController
        tabBarController.viewControllers?.forEach { navController in
            XCTAssertTrue(navController is UINavigationController)
        }
    }

    func testNavigationItemConfigured() {
        // Test if the navigation item is configured properly
        XCTAssertTrue(tabBarController.navigationItem.hidesBackButton)

        let barButton = tabBarController.navigationItem.rightBarButtonItem
        XCTAssertNotNil(barButton)
        XCTAssertEqual(barButton?.tintColor, UIColor.white)
    }
}
