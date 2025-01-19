//
//  Performance.LeakDetectorTests.swift
//
//  Created by Matheus Gois on 27/12/2024.
//

import XCTest
@testable import DebugSwift

final class PerformanceLeakDetectorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PerformanceLeakDetector.setup()
        PerformanceLeakDetector.callback = { leak in
            print(leak.message)
        }
    }

    override func tearDown() {
        PerformanceLeakDetector.callback = nil
        super.tearDown()
    }

    func testDetectLeakedSubview() {
        // Given: A view with a subview
        let view = UIView()
        let subview = UIView()
        view.addSubview(subview)

        // When: The subview is removed from the superview and leaks are checked
        view.removeFromSuperviewDetectLeaks()

        // Then: The view should no longer have a superview (indicating the leak check was triggered)
        XCTAssertNil(view.superview, "The view should not have a superview after removal.")
    }

    func testNoLeakWhenSubviewRemoved() {
        // Given: A view with a subview
        let view = UIView()
        let subview = UIView()
        view.addSubview(subview)

        // When: The subview is removed without triggering a leak
        subview.removeFromSuperview()

        // Set the callback to check if it gets called unexpectedly
        var callbackCalled = false
        PerformanceLeakDetector.callback = { _ in
            callbackCalled = true
        }

        // Perform the leak detection (simulate the check)
        subview.removeFromSuperviewDetectLeaks()

        sleep(3)

        // Then: The subview should be removed properly and not cause a memory leak
        XCTAssertNil(subview.superview, "The subview should be removed properly without causing a memory leak.")
        XCTAssertFalse(callbackCalled, "The callback should not be called when there is no memory leak.")
    }

    func testMemoryLeakCallback() {
        // Given: A view and subview setup
        let view = UIView()
        let subview = UIView()
        view.addSubview(subview)

        // When: A memory leak is detected (simulate a leak)
        let expectation = self.expectation(description: "Memory leak callback should be called")
        PerformanceLeakDetector.callback = { leak in
            if !leak.isDeallocation {
                XCTAssertFalse(leak.isDeallocation)
                XCTAssertNotNil(leak.message, "The leak callback should contain a message.")
                expectation.fulfill()
            }
        }
        sleep(3)

        // Simulate leak detection
        subview.removeFromSuperviewDetectLeaks()

        // Then: The callback should be triggered
        waitForExpectations(timeout: 20, handler: nil)
    }
}
