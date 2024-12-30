//
//  UIViewController+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UIViewControllerTests: XCTestCase {

    func testSetupKeyboardDismissGesture() {
        // Given
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        // When
        viewController.setupKeyboardDismissGesture()

        // Then
        let gestures = viewController.view.gestureRecognizers
        XCTAssertNotNil(gestures)
        XCTAssertTrue(gestures?.contains(where: { $0 is UITapGestureRecognizer }) ?? false)
    }

    func testAddRightBarButtonWithTitle() {
        // Given
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        // When
        viewController.addRightBarButton(title: "Test")

        // Then
        XCTAssertNotNil(viewController.navigationItem.rightBarButtonItem)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItem?.title, "Test")
    }

    func testAddRightBarButtonWithImage() {
        // Given
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()
        let testImage = UIImage()

        // When
        viewController.addRightBarButton(image: testImage)

        // Then
        XCTAssertNotNil(viewController.navigationItem.rightBarButtonItem)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItem?.image, testImage)
    }

    func testAddRightBarButtonWithActions() {
        // Given
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()
        let testImage = UIImage()
        let actions = [UIViewController.ButtonAction(image: testImage)]

        // When
        viewController.addRightBarButton(actions: actions)

        // Then
        XCTAssertNotNil(viewController.navigationItem.rightBarButtonItems)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems?.count, actions.count)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems?.first?.image, testImage)
    }

    func testAddLeftBarButton() {
        // Given
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()
        let testImage = UIImage()

        // When
        viewController.addLeftBarButton(image: testImage)

        // Then
        XCTAssertNotNil(viewController.navigationItem.leftBarButtonItem)
        XCTAssertEqual(viewController.navigationItem.leftBarButtonItem?.image, testImage)
    }
}
