//
//  DiskMetrics.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation

struct DiskIOSample: Sendable {
    let bytesPerSecond: Double
    let timestamp: Date

    init(bytesPerSecond: Double, timestamp: Date = Date()) {
        self.bytesPerSecond = bytesPerSecond
        self.timestamp = timestamp
    }
}

struct OpenFileDescriptor: Identifiable, Sendable {
    enum FileType: String, Sendable {
        case readOnly = "R"
        case writeOnly = "W"
        case readWrite = "RW"
    }

    let id: Int
    let descriptor: Int32
    let path: String
    let fileType: FileType

    init(descriptor: Int32, path: String, fileType: FileType) {
        self.id = Int(descriptor)
        self.descriptor = descriptor
        self.path = path
        self.fileType = fileType
    }
}

struct DiskUsageInfo {
    let totalSpace: Int64
    let freeSpace: Int64
    let usedSpace: Int64
    let bundleSize: Int64
    let cachesSize: Int64
    let tempSize: Int64
    let documentsSize: Int64

    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }
}
