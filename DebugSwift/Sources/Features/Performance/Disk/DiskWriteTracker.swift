//
//  DiskWriteTracker.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation
import MetricKit

/// Tracks cumulative disk writes via NSData swizzling (real-time)
/// and MetricKit MXDiskIOMetric (24h aggregate).
/// Call `install()` once at app launch.
public final class DiskWriteTracker: NSObject, @unchecked Sendable {
    public static let shared = DiskWriteTracker()

    private let lock = NSLock()
    private var installed = false
    private var _totalWriteBytes: UInt64 = 0
    private var _metricKitCumulativeWrites: String?

    private override init() {
        super.init()
    }

    /// Install the tracker. Safe to call multiple times.
    public static func install() {
        shared.doInstall()
    }

    private func doInstall() {
        lock.lock()
        defer { lock.unlock() }
        guard !installed else { return }
        installed = true
        Self.swizzleWrite()
        MXMetricManager.shared.add(self)
    }

    func recordWrite(bytes: UInt64) {
        lock.lock()
        _totalWriteBytes += bytes
        lock.unlock()
    }

    /// Total bytes written since `install()` (swizzle-based, real-time).
    public var totalBytesWritten: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return _totalWriteBytes
    }

    /// Last 24h cumulative logical writes reported by MetricKit, or nil if not yet received.
    public var metricKitCumulativeWrites: String? {
        lock.lock()
        defer { lock.unlock() }
        return _metricKitCumulativeWrites
    }

    // MARK: - Swizzling

    private static func swizzleWrite() {
        let cls: AnyClass = NSData.self
        let originalSelector = #selector(NSData.write(to:options:))
        let swizzledSelector = #selector(NSData.debugswift_write(to:options:))

        guard
            let originalMethod = class_getInstanceMethod(cls, originalSelector),
            let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

// MARK: - MXMetricManagerSubscriber

extension DiskWriteTracker: MXMetricManagerSubscriber {
    public func didReceive(_ payloads: [MXMetricPayload]) {
        guard let latest = payloads.last,
              let diskIO = latest.diskIOMetrics else { return }

        let measurement = diskIO.cumulativeLogicalWrites
        let bytes = measurement.converted(to: .bytes).value
        let formatted = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)

        lock.lock()
        _metricKitCumulativeWrites = formatted
        lock.unlock()
    }
}

// MARK: - NSData Swizzling

extension NSData {
    @objc dynamic func debugswift_write(to url: URL, options: NSData.WritingOptions) throws {
        try debugswift_write(to: url, options: options)
        DiskWriteTracker.shared.recordWrite(bytes: UInt64(self.length))
    }
}
