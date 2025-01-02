//
//  Performace.FPSCalculatorTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 27/12/2024.
//

import XCTest
@testable import DebugSwift

class FPSCounterTests: XCTestCase {

    var fpsCounter: FPSCounter!

    override func setUp() {
        super.setUp()
        fpsCounter = FPSCounter()
    }

    override func tearDown() {
        fpsCounter = nil
        super.tearDown()
    }

    func testNotificationDelay() {
        // Given
        let expectedDelay: TimeInterval = 2.0

        // When
        fpsCounter.notificationDelay = expectedDelay

        // Then
        XCTAssertEqual(fpsCounter.notificationDelay, expectedDelay)
    }
}
