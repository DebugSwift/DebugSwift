//
//  StderrCaptureTests.swift
//  ExampleTests
//
//  Regression test for issue #433: StderrCapture.startCapturingInternal()
//  leaked unbounded _Block_copy allocations because the readabilityHandler
//  deferred availableData consumption into a captureQueue.async block, so the
//  read source stayed signalled and re-fired immediately, enqueuing a new
//  dispatch block per callback. This test verifies that:
//
//    1. A single stderr write produces exactly one console entry (not
//       thousands — the leak symptom).
//    2. stopCapturing restores fd 2 to the real stderr so post-stop writes
//       do not appear in the console (the originalDescriptor / freopen
//       ordering bug).
//

import XCTest
@testable import DebugSwift

final class StderrCaptureTests: XCTestCase {

    private func waitForCaptureReady() {
        // startCapturing() dispatches startCapturingInternal() to
        // captureQueue.async and returns immediately. Poll isCapturing
        // until it flips true — which now means the dup2 redirect has
        // landed and the readabilityHandler is armed. A fixed sleep was
        // racy under CI startup load: the marker was written to fd 2
        // while it still pointed at real stderr and escaped capture (#433).
        let deadline = Date().addingTimeInterval(5)
        while !StderrCapture.shared.isCapturing, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    /// Stop capture and wait for the serial captureQueue to drain so fd 2
    /// is fully restored before the next call.
    private func stopAndDrain(_ timeout: TimeInterval = 0.5) {
        StderrCapture.shared.stopCapturing()
        let exp = expectation(description: "stop-drained")
        DispatchQueue(label: "test.drain").asyncAfter(deadline: .now() + timeout) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    override func setUp() {
        // The app may have started StderrCapture at launch (enableCrashManager
        // → startCapturing). Stop it and drain so every test starts from a
        // known-stopped state and exercises a real startCapturing →
        // startCapturingInternal path through the fixed code.
        stopAndDrain()
        super.setUp()
    }

    override func tearDown() {
        // Always stop so fd 2 is restored even if a test fails mid-way.
        stopAndDrain()
        super.tearDown()
    }

    // MARK: - Capture

    /// A single write to stderr after start should surface exactly one entry
    /// in ConsoleOutput's error list — not hundreds/thousands, which is the
    /// runaway-dispatch-block symptom from #433.
    func testSingleStderrWriteProducesOneConsoleEntry() throws {
        StderrCapture.shared.startCapturing()
        // Wait for the dup2 redirect to land before writing (see
        // waitForCaptureReady).
        waitForCaptureReady()
        // The simulator test environment may not support fd-2 redirect
        // (dup() can fail), in which case startCapturingInternal bails
        // out. Skip cleanly — the regression assertion is only meaningful
        // when capture is actually live.
        guard StderrCapture.shared.isCapturing else {
            throw XCTSkip("stderr fd-2 redirect unsupported in this environment")
        }

        // Write a distinctive marker to stderr (fd 2, now redirected).
        let marker = "DSWIFT_433_MARKER_\(UUID().uuidString)"
        FileHandle.standardError.write(Data((marker + "\n").utf8))

        // Poll for the marker to land in ConsoleOutput. The readabilityHandler
        // dispatches parsing to a serial processingQueue; under CI load a
        // fixed sleep can elapse before the marker reaches addErrorOutput,
        // producing a false failure — the exact CI failure mode from #433.
        let deadline = Date().addingTimeInterval(5)
        var matches: [String] = []
        while Date() < deadline {
            matches = ConsoleOutput.shared.getErrorOutput().filter { $0.contains(marker) }
            if !matches.isEmpty { break }
            Thread.sleep(forTimeInterval: 0.01)
        }


        // Must receive the marker at least once (capture works).
        XCTAssertFalse(matches.isEmpty, "stderr marker was not captured")
        // The leak symptom: the readabilityHandler re-fires and enqueues a
        // block per callback, so the marker would appear many times. With the
        // fix, one write → one entry (allow a small tolerance for the
        // passthrough/read-source draining).
        XCTAssertLessThanOrEqual(matches.count, 2,
            "stderr marker appeared \(matches.count) times — readabilityHandler is re-firing (leak #433)")
    }

    // MARK: - Passthrough (recursion fix)

    /// Writing a stderr line containing "]" triggers stderrMessageSafe →
    /// writeDirectlyToOriginalStderr, which writes the post-"]" fragment to
    /// originalDescriptor. Before the fix, originalDescriptor aliased fd 2
    /// (the capture pipe), so the fragment re-entered the capture loop and
    /// appeared as its own console error entry. After the fix,
    /// originalDescriptor is an owned dup of real stderr, so the fragment
    /// exits the pipe and only the original full marker is captured.
    func testStderrPassthroughDoesNotRecurse() throws {
        StderrCapture.shared.startCapturing()
        waitForCaptureReady()
        guard StderrCapture.shared.isCapturing else {
            throw XCTSkip("stderr fd-2 redirect unsupported in this environment")
        }

        // The "]" triggers the writeDirectlyToOriginalStderr code path in
        // stderrMessageSafe, which splits on "]", removes the first segment,
        // and writes the remainder to originalDescriptor.
        let uuid = UUID().uuidString
        let marker = "[DSWIFT_433_PASSTHROUGH] \(uuid)"
        FileHandle.standardError.write(Data((marker + "\n").utf8))

        // Poll for the marker to land in ConsoleOutput — same rationale as
        // testSingleStderrWriteProducesOneConsoleEntry: the serial
        // processingQueue can lag under CI load, and a fixed sleep produced
        // the exact false-failure mode from #433.
        let deadline = Date().addingTimeInterval(5)
        var fullMatches: [String] = []
        while Date() < deadline {
            fullMatches = ConsoleOutput.shared.getErrorOutput().filter { $0.contains(marker) }
            if !fullMatches.isEmpty { break }
            Thread.sleep(forTimeInterval: 0.01)
        }

        // The full marker must be captured once (capture works).
        XCTAssertFalse(fullMatches.isEmpty, "passthrough marker was not captured")
        XCTAssertLessThanOrEqual(fullMatches.count, 2,
            "full marker appeared \(fullMatches.count) times — readabilityHandler is re-firing (leak #433)")

        // The distinguishing assertion for the recursion fix:
        // stderrMessageSafe splits on "]", removes the first segment, and
        // writes the trimmed remainder (the bare uuid) to
        // writeDirectlyToOriginalStderr. Pre-fix, originalDescriptor aliased
        // the capture pipe, so the bare uuid re-entered the loop and appeared
        // as its own console error entry. Post-fix, it goes to real stderr
        // and must NOT appear as a standalone entry.
        let errors = ConsoleOutput.shared.getErrorOutput()
        let bareFragmentMatches = errors.filter {
            $0.trimmingCharacters(in: .whitespacesAndNewlines) == uuid
        }
        XCTAssertTrue(bareFragmentMatches.isEmpty,
            "bare uuid fragment '\(uuid)' appeared as its own console entry — writeDirectlyToOriginalStderr re-entered the capture pipe (recursion bug)")
    }

    // MARK: - Stop restores stderr

    /// After stopCapturing, writing to stderr must NOT show up in the console
    /// — fd 2 should be restored to the real stderr, not left pointing at the
    /// capture pipe (the originalDescriptor/freopen ordering bug).
    func testStopRestoresStderr() throws {
        StderrCapture.shared.startCapturing()
        waitForCaptureReady()
        guard StderrCapture.shared.isCapturing else {
            throw XCTSkip("stderr fd-2 redirect unsupported in this environment")
        }

        stopAndDrain()

        let marker = "DSWIFT_433_POSTSTOP_\(UUID().uuidString)"
        FileHandle.standardError.write(Data((marker + "\n").utf8))

        // Wait briefly for any (undesired) capture.
        let exp = expectation(description: "poststop-wait")
        DispatchQueue(label: "test.poststop").asyncAfter(deadline: .now() + 0.5) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        let errors = ConsoleOutput.shared.getErrorOutput()
        let matches = errors.filter { $0.contains(marker) }
        XCTAssertTrue(matches.isEmpty,
            "post-stop stderr write was captured — fd 2 was not restored (stopCapturingInternal bug)")
    }
}
