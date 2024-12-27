//
//  FloatViewManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class FloatViewManagerTests: XCTestCase {

    func testSetup() {
        // Given
        let viewController = UIViewController()

        // When
        FloatViewManager.setup(viewController)

        // Then
        XCTAssertEqual(FloatViewManager.shared.floatViewController, viewController, "The floatViewController should be set correctly")
    }

    func testIsShowing() {
        // When
        let isShowing = FloatViewManager.isShowing()

        // Then
        XCTAssertEqual(isShowing, FloatViewManager.shared.ballView.isShowing, "The isShowing should return the correct value")
    }

    func testShow() {
        // When
        FloatViewManager.show()

        // Then
        XCTAssertTrue(FloatViewManager.shared.ballView.show, "The ballView should be shown")
    }

    func testRemove() {
        // When
        FloatViewManager.remove()

        // Then
        XCTAssertFalse(FloatViewManager.shared.ballView.show, "The ballView should be removed")
    }

    func testToggle() {
        // Given
        let initialShowState = FloatViewManager.shared.ballView.show

        // When
        FloatViewManager.toggle()

        // Then
        XCTAssertEqual(FloatViewManager.shared.ballView.show, !initialShowState, "The ballView show state should be toggled")
    }

    func testIsShowingDebuggerView() {
        // Given
        let isShowingDebuggerView = true

        // When
        FloatViewManager.isShowingDebuggerView = isShowingDebuggerView

        // Then
        XCTAssertEqual(FloatViewManager.shared.ballView.isHidden, isShowingDebuggerView, "The ballView hidden state should be set correctly")
    }
}
