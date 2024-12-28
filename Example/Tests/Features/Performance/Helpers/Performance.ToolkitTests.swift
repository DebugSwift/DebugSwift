//
//  Performance.ToolkitTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 27/12/2024.
//

import XCTest
@testable import DebugSwift

final class PerformanceToolkitTests: XCTestCase {
    var toolkit: PerformanceToolkit!
    var mockDelegate: MockPerformanceToolkitDelegate!
    var mockWidgetDelegate: MockPerformanceWidgetViewDelegate!

    override func setUp() {
        super.setUp()
        mockDelegate = MockPerformanceToolkitDelegate()
        mockWidgetDelegate = MockPerformanceWidgetViewDelegate()
        toolkit = PerformanceToolkit(widgetDelegate: mockWidgetDelegate)
        toolkit.delegate = mockDelegate
    }

    override func tearDown() {
        toolkit = nil
        mockDelegate = nil
        mockWidgetDelegate = nil
        super.tearDown()
    }

    func testSetupPerformanceMeasurement() {
        // Given
        toolkit.setupPerformanceMeasurement()

        // When
        let timer = toolkit.measurementsTimer

        // Then
        XCTAssertNotNil(timer)
        XCTAssertEqual(toolkit.cpuMeasurements.count, toolkit.measurementsLimit)
        XCTAssertEqual(toolkit.memoryMeasurements.count, toolkit.measurementsLimit)
        XCTAssertEqual(toolkit.fpsMeasurements.count, toolkit.measurementsLimit)
        XCTAssertEqual(toolkit.leaksMeasurements.count, toolkit.measurementsLimit)
    }

    func testCPU() {
        // When
        let cpuUsage = toolkit.cpu()

        // Then
        XCTAssertGreaterThanOrEqual(cpuUsage, 0)
    }

}

class MockPerformanceToolkitDelegate: PerformanceToolkitDelegate {
    var didUpdateStatsCallCount = 0

    func performanceToolkitDidUpdateStats(_ toolkit: PerformanceToolkit) {
        didUpdateStatsCallCount += 1
    }
}

class MockPerformanceWidgetViewDelegate: PerformanceWidgetViewDelegate {
    func performanceWidgetView(_ performanceWidgetView: PerformanceWidgetView, didTapOnSection section: PerformanceSection) { }

    var updatedValues: [String: CGFloat] = [:]

    func updateValues(cpu: CGFloat, memory: CGFloat, fps: CGFloat, leaks: CGFloat) {
        updatedValues["cpu"] = cpu
        updatedValues["memory"] = memory
        updatedValues["fps"] = fps
        updatedValues["leaks"] = leaks
    }
}
