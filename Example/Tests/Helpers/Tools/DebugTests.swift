// DebugTests.swift
// Author: Matheus Gois
// Date: 21/12/2024
// Based on Given methodology

import XCTest
@testable import DebugSwift

class DebugTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        Debug.enable = true
    }

    override func tearDownWithError() throws {
        Debug.enable = false
        try super.tearDownWithError()
    }

    func testEnableDebug() {
        Debug.enable = true
        XCTAssertTrue(Debug.enable)
    }

    func testDisableDebug() {
        Debug.enable = false
        XCTAssertFalse(Debug.enable)
    }

    func testExecuteActionWhenEnabled() {
        Debug.enable = true
        var executed = false
        Debug.execute {
            executed = true
        }
        XCTAssertTrue(executed)
    }

    func testExecuteActionWhenDisabled() {
        Debug.enable = false
        var executed = false
        Debug.execute {
            executed = true
        }
        XCTAssertFalse(executed)
    }
}
