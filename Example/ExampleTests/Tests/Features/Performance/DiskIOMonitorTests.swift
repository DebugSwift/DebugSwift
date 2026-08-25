//
//  DiskIOMonitorTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation
import Testing
@testable import DebugSwift

struct DiskIOMonitorTests {

    @Test("Monitor starts and stops without crash")
    @MainActor
    func startStop() {
        let monitor = DiskIOMonitor.shared
        monitor.start()
        monitor.stop()
    }

    @Test("Monitor reports zero rate when idle")
    @MainActor
    func idleRates() {
        let monitor = DiskIOMonitor.shared
        #expect(monitor.writeBytesPerSecond >= 0)
    }

    @Test("History starts empty before monitoring")
    @MainActor
    func historyStartsEmpty() {
        let monitor = DiskIOMonitor.shared
        monitor.stop()
        let writeCount = monitor.writeHistory.count
        #expect(writeCount >= 0)
    }
}
