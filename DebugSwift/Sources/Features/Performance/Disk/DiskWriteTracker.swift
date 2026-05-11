//
//  DiskWriteTracker.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation

/// Tracks cumulative disk writes by swizzling `NSData.write(to:options:)`.
/// Call `install()` once at app launch.
public final class DiskWriteTracker: @unchecked Sendable {
    public static let shared = DiskWriteTracker()

    private let lock = NSLock()
    private var installed = false
    private var _totalWriteBytes: UInt64 = 0

    private init() {}

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
    }

    func recordWrite(bytes: UInt64) {
        lock.lock()
        _totalWriteBytes += bytes
        lock.unlock()
    }

    /// Total bytes written since `install()`.
    public var totalBytesWritten: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return _totalWriteBytes
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

// MARK: - NSData Swizzling

extension NSData {
    @objc dynamic func debugswift_write(to url: URL, options: NSData.WritingOptions) throws {
        try debugswift_write(to: url, options: options)
        DiskWriteTracker.shared.recordWrite(bytes: UInt64(self.length))
    }
}
