import XCTest
@testable import DebugSwift

final class PerformanceMemoryMonitorTests: XCTestCase {
    @MainActor
    func testSwitchClearsHistoryAndPeakEvenWhenFirstSampleIsUnavailable() {
        let original = DebugSwift.Performance.Memory.metric
        defer { DebugSwift.Performance.Memory.metric = original }

        DebugSwift.Performance.Memory.metric = .rss
        var monitor = PerformanceMemoryMonitor()
        monitor.update(limit: 120) { _ in 100 }
        monitor.update(limit: 120) { _ in 200 }

        DebugSwift.Performance.Memory.metric = .physFootprint
        monitor.update(limit: 120) { metric in
            XCTAssertEqual(metric, .physFootprint)
            return nil
        }

        XCTAssertNil(monitor.current)
        XCTAssertNil(monitor.peak)
        XCTAssertTrue(monitor.history.isEmpty)

        monitor.update(limit: 120) { _ in 30 }
        monitor.update(limit: 120) { _ in nil }
        monitor.update(limit: 120) { _ in 40 }

        XCTAssertEqual(monitor.current, 40)
        XCTAssertEqual(monitor.peak, 40)
        XCTAssertEqual(monitor.history, [30, 40])
    }

    @MainActor
    func testRoundTripBetweenSamplesResetsStatistics() {
        let original = DebugSwift.Performance.Memory.metric
        defer { DebugSwift.Performance.Memory.metric = original }

        DebugSwift.Performance.Memory.metric = .rss
        var monitor = PerformanceMemoryMonitor()
        monitor.update(limit: 120) { _ in 100 }

        DebugSwift.Performance.Memory.metric = .physFootprint
        DebugSwift.Performance.Memory.metric = .rss
        monitor.update(limit: 120) { _ in 50 }

        XCTAssertEqual(monitor.metric, .rss)
        XCTAssertEqual(monitor.peak, 50)
        XCTAssertEqual(monitor.history, [50])
    }

    @MainActor
    func testBothMetricsReadProcessMemory() {
        let original = DebugSwift.Performance.Memory.metric
        defer { DebugSwift.Performance.Memory.metric = original }

        DebugSwift.Performance.Memory.metric = .rss
        var monitor = PerformanceMemoryMonitor()
        monitor.update(limit: 120)
        XCTAssertGreaterThan(monitor.current ?? 0, 0)

        DebugSwift.Performance.Memory.metric = .physFootprint
        monitor.update(limit: 120)
        XCTAssertGreaterThan(monitor.current ?? 0, 0)
        XCTAssertEqual(monitor.history.count, 1)
    }
}
