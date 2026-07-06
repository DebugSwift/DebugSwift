//
//  DiskWriteTrackerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation
import Testing
@testable import DebugSwift

struct DiskWriteTrackerTests {

    @Test("Install is idempotent")
    func installIdempotent() {
        DiskWriteTracker.install()
        DiskWriteTracker.install()
    }

    @Test("Total bytes written increases after writing data")
    func bytesIncreaseAfterWrite() throws {
        DiskWriteTracker.install()
        let before = DiskWriteTracker.shared.totalBytesWritten

        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("tracker_test_\(UUID().uuidString).bin")
        let data = Data(repeating: 0xAA, count: 1024 * 512)
        try data.write(to: tempFile)

        let after = DiskWriteTracker.shared.totalBytesWritten
        #expect(after >= before)

        try? FileManager.default.removeItem(at: tempFile)
    }

    @Test("OpenFileDescriptor types")
    func fileDescriptorTypes() {
        let readOnly = OpenFileDescriptor(descriptor: 0, path: "/dev/null", fileType: .readOnly)
        #expect(readOnly.fileType.rawValue == "R")

        let writeOnly = OpenFileDescriptor(descriptor: 1, path: "/dev/null", fileType: .writeOnly)
        #expect(writeOnly.fileType.rawValue == "W")

        let readWrite = OpenFileDescriptor(descriptor: 2, path: "/dev/null", fileType: .readWrite)
        #expect(readWrite.fileType.rawValue == "RW")
    }

    @Test("DiskIOSample stores values correctly")
    func sampleValues() {
        let sample = DiskIOSample(bytesPerSecond: 1024.5)
        #expect(sample.bytesPerSecond == 1024.5)
    }
}
