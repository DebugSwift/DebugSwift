//
//  HangDetector.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation

// MARK: - #5 Hangs / ANR Detection (pure watchdog logic)

/// A hang event reported by `HangDetector` when the main thread stops
/// heartbeating within the configured threshold (after the grace period).
public struct HangEvent: Equatable {
    public let timestamp: Date
    public let duration: Double
    public let backtrace: [String]

    public init(timestamp: Date = Date(), duration: Double, backtrace: [String] = []) {
        self.timestamp = timestamp
        self.duration = duration
        self.backtrace = backtrace
    }
}

/// Pure hang/ANR detection logic.
///
/// The detection core — threshold comparison, grace-period gating,
/// last-ping tracking — is pure date arithmetic. The real
/// `DispatchSource.timer` and `Thread.callStackSymbols` are thin adapters
/// around this logic, supplied by `HangDetectorRunner`. Tests inject
/// `Date` values directly.
public final class HangDetector {

    /// Minimum main-thread stall (seconds) considered a hang.
    public var threshold: Double

    /// Seconds after `start()` during which no hang is reported, to allow
    /// for app launch.
    public var gracePeriod: Double

    private var lastPing = Date()
    private var startedAt: Date?
    private var hangHandler: ((HangEvent) -> Void)?

    public init(threshold: Double = 0.25, gracePeriod: Double = 10) {
        self.threshold = threshold
        self.gracePeriod = gracePeriod
    }

    /// Register a callback invoked when a hang is detected.
    public func onHang(_ handler: @escaping (HangEvent) -> Void) {
        hangHandler = handler
    }

    /// Begin monitoring. `now` is injectable for testing.
    public func start(now: Date = Date()) {
        startedAt = now
        lastPing = now
    }

    /// Called from the main thread to record a heartbeat. `now` is injectable
    /// for testing.
    public func mainThreadDidHeartbeat(now: Date = Date()) {
        lastPing = now
    }

    /// Called periodically (e.g. by a `DispatchSource.timer`) to check whether
    /// the main thread has stalled. `now` and `backtrace` are injectable for
    /// testing.
    public func watchdogTick(now: Date, backtrace: [String] = []) {
        guard let started = startedAt, now.timeIntervalSince(started) > gracePeriod else { return }
        let elapsed = now.timeIntervalSince(lastPing)
        if elapsed >= threshold {
            hangHandler?(HangEvent(timestamp: now, duration: elapsed, backtrace: backtrace))
        }
    }

    /// Stop monitoring and clear state.
    public func stop() {
        startedAt = nil
    }
}
