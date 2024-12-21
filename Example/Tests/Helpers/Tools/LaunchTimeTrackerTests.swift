//
//  LaunchTimeTrackerTests.swift
//  LaunchTimeTrackerTests
//
//  Created by Matheus Gois on 21/12/2024.
//  Based on Given methodology

import XCTest
@testable import DebugSwift

class LaunchTimeTrackerTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        LaunchTimeTracker.launchStartTime = nil
    }

    override func tearDownWithError() throws {
        LaunchTimeTracker.launchStartTime = nil
        try super.tearDownWithError()
    }

    func testMeasureAppStartUpTime() {
        LaunchTimeTracker.measureAppStartUpTime()
        XCTAssertNotNil(LaunchTimeTracker.launchStartTime)
        XCTAssertGreaterThan(LaunchTimeTracker.launchStartTime!, 0)
    }

    func testLaunchStartTimeInitialValue() {
        XCTAssertNil(LaunchTimeTracker.launchStartTime)
    }
}
