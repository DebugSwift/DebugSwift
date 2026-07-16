//
//  HangDetectorTests.swift
//  ExampleTests
//
//  Created by Matheus Gois on 16/07/26.
//

import XCTest
@testable import DebugSwift

final class HangDetectorTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a deterministic date from a time interval since the reference date,
    /// so tests can simulate the passage of time without real delays.
    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }

    // MARK: - HangDetector Tests

    func testNoHang_beforeGracePeriod() {
        let detector = HangDetector()
        var didFire = false
        detector.onHang { _ in didFire = true }

        detector.start(now: date(0))

        // Tick within the 10-second grace period — no hang should fire.
        detector.watchdogTick(now: date(5))
        XCTAssertFalse(didFire)
    }

    func testHang_afterGraceAndThreshold() {
        let detector = HangDetector()
        var receivedEvent: HangEvent?
        detector.onHang { receivedEvent = $0 }

        detector.start(now: date(0))

        // Heartbeat after the grace period (11 s > 10 s).
        detector.mainThreadDidHeartbeat(now: date(11))

        // Tick 1 s after the last heartbeat — exceeds the 0.25 s threshold.
        detector.watchdogTick(now: date(12))

        XCTAssertNotNil(receivedEvent)
    }

    func testHang_reportsAccurateDuration() {
        let detector = HangDetector()
        var receivedEvent: HangEvent?
        detector.onHang { receivedEvent = $0 }

        detector.start(now: date(0))

        // No heartbeat — lastPing stays at start.
        // Tick 15 s later: grace (10 s) passed, elapsed = 15 s >= threshold (0.25 s).
        detector.watchdogTick(now: date(15))

        XCTAssertNotNil(receivedEvent)
        XCTAssertEqual(receivedEvent?.duration, 15.0, accuracy: 0.001)
    }

    func testNoHang_whenHeartbeatRecent() {
        let detector = HangDetector()
        var didFire = false
        detector.onHang { _ in didFire = true }

        detector.start(now: date(0))

        // Heartbeat just before the tick.
        detector.mainThreadDidHeartbeat(now: date(15))
        // Tick 0.01 s later — well below the 0.25 s threshold.
        detector.watchdogTick(now: date(15.01))

        XCTAssertFalse(didFire)
    }

    func testHang_backtracePassedThrough() {
        let detector = HangDetector()
        var receivedEvent: HangEvent?
        detector.onHang { receivedEvent = $0 }

        detector.start(now: date(0))

        let backtrace = ["frame1", "frame2", "frame3"]
        detector.watchdogTick(now: date(15), backtrace: backtrace)

        XCTAssertNotNil(receivedEvent)
        XCTAssertEqual(receivedEvent?.backtrace, backtrace)
    }

    func testStop_clearsState() {
        let detector = HangDetector()
        var didFire = false
        detector.onHang { _ in didFire = true }

        detector.start(now: date(0))
        detector.stop()

        // Tick well past the grace period — should not fire because stop()
        // cleared startedAt, causing the guard to fail.
        detector.watchdogTick(now: date(15))
        XCTAssertFalse(didFire)
    }

    func testCustomThreshold_andGracePeriod() {
        let detector = HangDetector(threshold: 5, gracePeriod: 1)
        var receivedEvent: HangEvent?
        detector.onHang { receivedEvent = $0 }

        detector.start(now: date(0))

        // Past the 1-second grace, but elapsed (2 s) < threshold (5 s) — no hang.
        detector.watchdogTick(now: date(2))
        XCTAssertNil(receivedEvent)

        // Now elapsed (7 s) >= threshold (5 s) — hang fires.
        detector.watchdogTick(now: date(7))
        XCTAssertNotNil(receivedEvent)
    }

    func testHangEvent_isSendable() {
        let event = HangEvent(duration: 1.0, backtrace: ["frame"])

        // Compile-time proof: this only compiles if HangEvent conforms to Sendable.
        func requireSendable<T: Sendable>(_ value: T) { _ = value }
        requireSendable(event)
    }

    // MARK: - HangDetectorRunner Tests

    @MainActor
    func testShared_isNotNil() {
        XCTAssertNotNil(HangDetectorRunner.shared)
    }

    @MainActor
    func testStart_stop_doesNotCrash() {
        let runner = HangDetectorRunner.shared
        runner.start()
        runner.stop()
    }

    @MainActor
    func testEvents_startsEmpty() {
        let runner = HangDetectorRunner.shared
        runner.stop()
        // No hang should be recorded during a quick start/stop — the 10 s
        // grace period prevents false positives, so events stays empty.
        XCTAssertTrue(runner.events.isEmpty)
    }
}
