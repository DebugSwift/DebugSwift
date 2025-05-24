//
//  LaunchTimeTrackerTests.swift
//  DebugSwiftTests
//
//  Created by Matheus Gois on 21/12/2024.
//  Based on Given methodology

@testable import DebugSwift
import XCTest

class LaunchTimeTrackerTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        LaunchTimeTracker.shared.launchStartTime = nil
    }

    override func tearDownWithError() throws {
        LaunchTimeTracker.shared.launchStartTime = nil
        try super.tearDownWithError()
    }

    func testMeasureAppStartUpTime() {
        LaunchTimeTracker.shared.measureAppStartUpTime()
        XCTAssertNotNil(LaunchTimeTracker.shared.launchStartTime)
        XCTAssertGreaterThan(LaunchTimeTracker.shared.launchStartTime!, 0)
    }

    func testLaunchStartTimeInitialValue() {
        XCTAssertNil(LaunchTimeTracker.shared.launchStartTime)
    }
}
