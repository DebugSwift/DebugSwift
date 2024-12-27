//
//  WindowManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class WindowManagerTests: XCTestCase {

    func testPresentDebuggerWhenNotShowing() {
        // Given
        FloatViewManager.isShowingDebuggerView = false
        let mockViewController = UIViewController()
        FloatViewManager.setup(mockViewController)

        // When
        WindowManager.presentDebugger()

        // Then
        XCTAssertTrue(FloatViewManager.isShowingDebuggerView, "Debugger view should be showing")
        XCTAssertEqual(WindowManager.rootNavigation?.topViewController, mockViewController, "Top view controller should be the float view controller")
    }

    func testPresentDebuggerWhenAlreadyShowing() {
        // Given
        FloatViewManager.isShowingDebuggerView = true

        // When
        WindowManager.presentDebugger()

        // Then
        XCTAssertTrue(FloatViewManager.isShowingDebuggerView, "Debugger view should still be showing")
    }

    func testPresentViewDebuggerWhenAlreadyShowing() {
        // Given
        FloatViewManager.isShowingDebuggerView = true

        // When
        WindowManager.presentViewDebugger()

        // Then
        XCTAssertTrue(FloatViewManager.isShowingDebuggerView, "View debugger should still be showing")
    }

    func testRemoveViewDebugger() {
        // Given
        FloatViewManager.isShowingDebuggerView = true

        // When
        WindowManager.removeViewDebugger()

        // Then
        XCTAssertFalse(FloatViewManager.isShowingDebuggerView, "View debugger should not be showing")
    }
}
