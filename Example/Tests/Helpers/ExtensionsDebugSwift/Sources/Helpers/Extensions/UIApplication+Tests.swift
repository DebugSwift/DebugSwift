//
//  UIApplication+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UIApplicationTests: XCTestCase {

    func testTopViewControllerWithNavigationController() {
        // Given
        let navigationController = UINavigationController()
        let viewController = UIViewController()
        navigationController.viewControllers = [viewController]

        // When
        let topViewController = UIApplication.topViewController(navigationController)

        // Then
        XCTAssertEqual(topViewController, viewController, "The top view controller should be the visible view controller in the navigation controller")
    }

    func testTopViewControllerWithTabBarController() {
        // Given
        let tabBarController = UITabBarController()
        let viewController = UIViewController()
        tabBarController.viewControllers = [viewController]
        tabBarController.selectedViewController = viewController

        // When
        let topViewController = UIApplication.topViewController(tabBarController)

        // Then
        XCTAssertEqual(topViewController, viewController, "The top view controller should be the selected view controller in the tab bar controller")
    }

    func testTopViewControllerWithPresentedViewController() {
        // Given
        let rootViewController = UIViewController()
        let presentedViewController = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        rootViewController.present(presentedViewController, animated: false, completion: nil)

        // When
        let topViewController = UIApplication.topViewController(rootViewController)

        // Then
        XCTAssertEqual(topViewController, presentedViewController, "The top view controller should be the presented view controller")
    }

    func testTopViewControllerWithRootViewController() {
        // Given
        let rootViewController = UIViewController()

        // When
        let topViewController = UIApplication.topViewController(rootViewController)

        // Then
        XCTAssertEqual(topViewController, rootViewController, "The top view controller should be the root view controller")
    }
}
