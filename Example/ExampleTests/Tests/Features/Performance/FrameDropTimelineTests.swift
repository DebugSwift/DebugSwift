//
//  FrameDropTimelineTests.swift
//  ExampleTests
//
//  Created by Matheus Gois on 16/07/26.
//

import XCTest
import QuartzCore
@testable import DebugSwift

final class FrameDropTimelineTests: XCTestCase {

    // MARK: - Helpers

    private func makeTimeline(
        capacity: Int = 5000,
        dropThreshold: Double = 58,
        sampleEveryN: Int = 5
    ) -> FrameDropTimeline {
        FrameDropTimeline(
            capacity: capacity,
            dropThreshold: dropThreshold,
            sampleEveryN: sampleEveryN
        )
    }

    private func fixedDate(_ offset: TimeInterval = 0) -> Date {
        Date(timeIntervalSince1970: 1_000_000 + offset)
    }

    // MARK: - record(_:timestamp:context:) Tests

    func testRecord_belowThreshold_recordsEvent() {
        let timeline = makeTimeline(dropThreshold: 58, sampleEveryN: 1)
        let stamp = fixedDate()

        timeline.record(fps: 30, timestamp: stamp, context: "scene-A")

        XCTAssertEqual(timeline.events.count, 1)
        let event = try? XCTUnwrap(timeline.events.first)
        XCTAssertEqual(event?.fps, 30)
        XCTAssertEqual(event?.timestamp, stamp)
    }

    func testRecord_atOrAboveThreshold_skipped() {
        let timeline = makeTimeline(dropThreshold: 58, sampleEveryN: 1)

        // exactly at threshold -> skipped (guard fps < dropThreshold)
        timeline.record(fps: 58, timestamp: fixedDate(0))
        // well above threshold -> skipped
        timeline.record(fps: 60, timestamp: fixedDate(1))
        // just below -> recorded
        timeline.record(fps: 57.9, timestamp: fixedDate(2))

        XCTAssertEqual(timeline.events.count, 1)
        XCTAssertEqual(timeline.events.first?.fps, 57.9)
    }

    // MARK: - Sampling Tests

    func testSampleEveryN_recordsEveryNthDrop() {
        let timeline = makeTimeline(sampleEveryN: 5)

        // 10 consecutive drops; counter starts at 0 and increments each drop.
        // Events land when counter.isMultiple(of: 5): counter 5 and 10 -> 2 events.
        for i in 0..<10 {
            timeline.record(fps: 30, timestamp: fixedDate(Double(i)))
        }

        XCTAssertEqual(timeline.events.count, 2)
    }

    // MARK: - Capacity / Eviction Tests

    func testEvictsOldestAtCapacity() {
        let timeline = makeTimeline(capacity: 3, sampleEveryN: 1)

        for i in 0..<5 {
            timeline.record(fps: 20, timestamp: fixedDate(Double(i)), context: "drop-\(i)")
        }

        XCTAssertEqual(timeline.events.count, 3)
        // oldest two evicted; survivors are drops 2, 3, 4
        XCTAssertEqual(timeline.events.map(\.context), ["drop-2", "drop-3", "drop-4"])
    }

    // MARK: - Clear Tests

    func testClear_removesAllEvents() {
        let timeline = makeTimeline(sampleEveryN: 1)
        timeline.record(fps: 30, timestamp: fixedDate())
        timeline.record(fps: 31, timestamp: fixedDate(1))
        XCTAssertEqual(timeline.events.count, 2)

        timeline.clear()

        XCTAssertTrue(timeline.events.isEmpty)
    }

    // MARK: - Context Tests

    func testContext_isPreserved() {
        let timeline = makeTimeline(sampleEveryN: 1)
        let stamp = fixedDate()

        timeline.record(fps: 30, timestamp: stamp, context: "heavy-scroll")
        let event = try? XCTUnwrap(timeline.events.first)

        XCTAssertEqual(event?.context, "heavy-scroll")
    }

    func testContext_defaultsToNil() {
        let timeline = makeTimeline(sampleEveryN: 1)

        timeline.record(fps: 30, timestamp: fixedDate())

        XCTAssertNil(timeline.events.first?.context)
    }

    // MARK: - Custom Threshold Tests

    func testCustomThreshold() {
        let timeline = makeTimeline(dropThreshold: 30, sampleEveryN: 1)

        // 35 >= 30 -> not recorded
        timeline.record(fps: 35, timestamp: fixedDate(0))
        XCTAssertFalse(timeline.events.contains { $0.fps == 35 })

        // 25 < 30 -> recorded
        timeline.record(fps: 25, timestamp: fixedDate(1))
        XCTAssertEqual(timeline.events.count, 1)
        XCTAssertEqual(timeline.events.first?.fps, 25)
    }

    // MARK: - Timestamp Tests

    func testTimestamp_isPreserved() {
        let timeline = makeTimeline(sampleEveryN: 1)
        let stamp = Date(timeIntervalSince1970: 2_000_000)

        timeline.record(fps: 45, timestamp: stamp)

        XCTAssertEqual(timeline.events.first?.timestamp, stamp)
    }

    // MARK: - FrameDropEvent Tests

    func testFrameDropEvent_equatableAndDefaults() {
        let stamp = fixedDate()

        let a = FrameDropEvent(timestamp: stamp, fps: 30)
        let b = FrameDropEvent(timestamp: stamp, fps: 30, context: nil)

        XCTAssertEqual(a, b)
        XCTAssertNil(a.context)

        let withCtx = FrameDropEvent(timestamp: stamp, fps: 30, context: "ctx")
        XCTAssertNotEqual(a, withCtx)
    }

    // MARK: - Default Init Tests

    func testDefaultInit_usesExpectedDefaults() {
        let timeline = FrameDropTimeline()

        XCTAssertEqual(timeline.capacity, 5000)
        XCTAssertEqual(timeline.dropThreshold, 58)
        XCTAssertEqual(timeline.sampleEveryN, 5)
        XCTAssertTrue(timeline.events.isEmpty)
    }

    func testSampleEveryN_clampedToOne() {
        let timeline = FrameDropTimeline(sampleEveryN: 0)

        XCTAssertEqual(timeline.sampleEveryN, 1)

        // A single drop still records because counter reaches 1 (multiple of 1).
        timeline.record(fps: 10, timestamp: fixedDate())
        XCTAssertEqual(timeline.events.count, 1)
    }
}

// MARK: - FrameDropAdapter Tests

@MainActor
final class FrameDropAdapterTests: XCTestCase {

    func testShared_isNotNil() {
        XCTAssertNotNil(FrameDropAdapter.shared)
    }

    func testStart_stop_doesNotCrash() {
        let adapter = FrameDropAdapter.shared

        adapter.start()
        adapter.stop()
        // second stop should also be safe (idempotent tear-down)
        adapter.stop()
    }

    func testTimeline_accessibleFromShared() {
        let adapter = FrameDropAdapter.shared

        XCTAssertTrue(adapter.timeline is FrameDropTimeline)
        XCTAssertNotNil(adapter.timeline)
    }

    func testStart_isIdempotent() {
        let adapter = FrameDropAdapter.shared

        adapter.start()
        adapter.start() // second start must not create a duplicate display link
        adapter.stop()
    }
}
