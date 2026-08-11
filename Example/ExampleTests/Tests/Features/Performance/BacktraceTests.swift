//
//  BacktraceTests.swift
//  ExampleTests
//
//  Tests for issue #162: Swift 6.2 SE-0419 Backtrace API integration.
//  Tests the programmatic backtrace capture via DebugSwift.Performance.Backtrace.
//

import XCTest
@testable import DebugSwift

final class BacktraceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        BacktraceManager.shared.clear()
        BacktraceManager.shared.callback = nil
    }

    override func tearDown() {
        BacktraceManager.shared.clear()
        BacktraceManager.shared.callback = nil
        super.tearDown()
    }

    // MARK: - Capture

    func testCaptureReturnsBacktraceWithFrames() {
        let bt = DebugSwift.Performance.Backtrace.capture(label: "test")

        XCTAssertEqual(bt.label, "test")
        XCTAssertFalse(bt.frames.isEmpty, "Captured backtrace should have at least one frame")
        XCTAssertNotNil(bt.id)
    }

    func testCaptureWithoutLabelStoresNilLabel() {
        let bt = DebugSwift.Performance.Backtrace.capture()

        XCTAssertNil(bt.label)
        XCTAssertFalse(bt.frames.isEmpty)
    }

    func testCaptureHasTimestampCloseToNow() {
        let before = Date()
        let bt = DebugSwift.Performance.Backtrace.capture()
        let after = Date()

        XCTAssertTrue(bt.timestamp >= before)
        XCTAssertTrue(bt.timestamp <= after)
    }

    func testFramesAreSequentiallyIndexed() {
        let bt = DebugSwift.Performance.Backtrace.capture(label: "indexing")

        for (idx, frame) in bt.frames.enumerated() {
            XCTAssertEqual(frame.index, idx, "Frame indices should be sequential from 0")
        }
    }

    func testFrameSymbolsAreNonEmpty() {
        let bt = DebugSwift.Performance.Backtrace.capture(label: "symbols")

        for frame in bt.frames {
            XCTAssertFalse(frame.symbol.isEmpty, "Each frame should have a non-empty symbol")
        }
    }

    // MARK: - Manager storage

    func testCaptureStoresInManager() {
        XCTAssertEqual(BacktraceManager.shared.backtraces.count, 0)

        _ = DebugSwift.Performance.Backtrace.capture(label: "store")

        XCTAssertEqual(BacktraceManager.shared.backtraces.count, 1)
    }

    func testNewestFirstOrdering() {
        _ = DebugSwift.Performance.Backtrace.capture(label: "first")
        Thread.sleep(forTimeInterval: 0.05)
        _ = DebugSwift.Performance.Backtrace.capture(label: "second")

        XCTAssertEqual(BacktraceManager.shared.backtraces.count, 2)
        XCTAssertEqual(BacktraceManager.shared.backtraces.first?.label, "second")
        XCTAssertEqual(BacktraceManager.shared.backtraces.last?.label, "first")
    }

    func testClearRemovesAllCaptures() {
        _ = DebugSwift.Performance.Backtrace.capture(label: "a")
        _ = DebugSwift.Performance.Backtrace.capture(label: "b")
        XCTAssertEqual(BacktraceManager.shared.backtraces.count, 2)

        DebugSwift.Performance.Backtrace.clear()

        XCTAssertTrue(BacktraceManager.shared.backtraces.isEmpty)
    }

    // MARK: - Public API mirror

    func testCapturedArrayMatchesManager() {
        _ = DebugSwift.Performance.Backtrace.capture(label: "mirror")

        XCTAssertEqual(
            DebugSwift.Performance.Backtrace.captured.count,
            BacktraceManager.shared.backtraces.count
        )
        XCTAssertEqual(
            DebugSwift.Performance.Backtrace.captured.first?.label,
            BacktraceManager.shared.backtraces.first?.label
        )
    }

    // MARK: - Callback

    func testOnCaptureCallbackFires() {
        let expectation = XCTestExpectation(description: "callback fires")

        DebugSwift.Performance.Backtrace.onCapture { bt in
            XCTAssertEqual(bt.label, "callback-test")
            expectation.fulfill()
        }

        _ = DebugSwift.Performance.Backtrace.capture(label: "callback-test")

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Capacity cap

    func testManagerCapsAt100Entries() {
        for i in 0..<105 {
            _ = DebugSwift.Performance.Backtrace.capture(label: "cap-\(i)")
        }

        XCTAssertEqual(BacktraceManager.shared.backtraces.count, 100)
        // Newest 100 should be kept (labels cap-5 through cap-104)
        XCTAssertEqual(BacktraceManager.shared.backtraces.first?.label, "cap-104")
        XCTAssertEqual(BacktraceManager.shared.backtraces.last?.label, "cap-5")
    }

    // MARK: - Internal frame filtering

    func testInternalFramesAreFilteredOut() {
        let bt = DebugSwift.Performance.Backtrace.capture(label: "filter")

        // No frame symbol should mention DebugSwift-internal capture plumbing.
        for frame in bt.frames {
            XCTAssertFalse(
                frame.symbol.contains("BacktraceCaptureEngine"),
                "Internal capture-engine frames should be filtered: \(frame.symbol)"
            )
            XCTAssertFalse(
                frame.symbol.contains("BacktraceManager"),
                "Internal manager frames should be filtered: \(frame.symbol)"
            )
        }
    }

    // MARK: - Unique IDs

    func testEachCaptureHasUniqueID() {
        _ = DebugSwift.Performance.Backtrace.capture(label: "id-1")
        _ = DebugSwift.Performance.Backtrace.capture(label: "id-2")

        let ids = BacktraceManager.shared.backtraces.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "All capture IDs should be unique")
    }
}
