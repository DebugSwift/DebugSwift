//
//  TopUIViewTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 21/12/2024.
//  Based on Given methodology

import XCTest
@testable import DebugSwift

class TopUIViewTests: XCTestCase {

    var topLevelViewWrapper: TopLevelViewWrapper!

    override func setUpWithError() throws {
        try super.setUpWithError()
        topLevelViewWrapper = TopLevelViewWrapper()
    }

    override func tearDownWithError() throws {
        topLevelViewWrapper = nil
        try super.tearDownWithError()
    }

    func testToggleWithTrue() {
        topLevelViewWrapper.toggle(with: true)
        XCTAssertFalse(topLevelViewWrapper.isHidden)
        XCTAssertEqual(topLevelViewWrapper.alpha, 1.0)
    }

    func testToggleWithFalse() {
        topLevelViewWrapper.toggle(with: false)
        XCTAssertEqual(topLevelViewWrapper.alpha, 0.0)
        XCTAssertNil(topLevelViewWrapper.superview)

    }

    func testShowWidgetWindow() {
        topLevelViewWrapper.showWidgetWindow()
        XCTAssertEqual(topLevelViewWrapper.alpha, 1.0)
        XCTAssertTrue(WindowManager.window.rootViewController?.view.subviews.contains(topLevelViewWrapper) ?? false)
    }

    func testRemoveWidgetWindow() {
        topLevelViewWrapper.showWidgetWindow()
        topLevelViewWrapper.removeWidgetWindow()
        XCTAssertFalse(WindowManager.window.rootViewController?.view.subviews.contains(topLevelViewWrapper) ?? false)
    }
}
