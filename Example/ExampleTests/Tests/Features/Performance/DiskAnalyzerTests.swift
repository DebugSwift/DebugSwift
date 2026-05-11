//
//  DiskAnalyzerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Testing
@testable import DebugSwift

struct DiskAnalyzerTests {

    @Test("DiskUsageInfo computed properties")
    func usagePercentage() {
        let info = DiskUsageInfo(
            totalSpace: 1000,
            freeSpace: 300,
            usedSpace: 700,
            bundleSize: 100,
            cachesSize: 50,
            tempSize: 25,
            documentsSize: 75
        )
        #expect(info.usedPercentage == 70.0)
    }

    @Test("DiskUsageInfo zero total space")
    func zeroTotal() {
        let info = DiskUsageInfo(
            totalSpace: 0,
            freeSpace: 0,
            usedSpace: 0,
            bundleSize: 0,
            cachesSize: 0,
            tempSize: 0,
            documentsSize: 0
        )
        #expect(info.usedPercentage == 0)
    }

    @Test("DiskAnalyzer measure populates info")
    @MainActor
    func measurePopulatesInfo() async throws {
        let analyzer = DiskAnalyzer()
        analyzer.measure()

        // Wait for async computation
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(analyzer.usageInfo != nil)
        if let info = analyzer.usageInfo {
            #expect(info.totalSpace > 0)
            #expect(info.freeSpace > 0)
            #expect(info.bundleSize >= 0)
        }
    }
}
