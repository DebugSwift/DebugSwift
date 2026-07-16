//
//  HangDetector.swift
//  DebugSwift
//
//  Created by Matheus Gois (ANR Detection) on 16/07/26.
//

import Foundation

// MARK: - Hangs / ANR Detection

/// A hang event reported by `HangDetector` when the main thread stops
/// heartbeating within the configured threshold.
///
/// Carrying the backtrace lets the UI surface *where* the main thread
/// was stuck, not just that it was.
public struct HangEvent: Equatable, Sendable {
    public let timestamp: Date
    public let duration: Double
    public let backtrace: [String]

    public init(timestamp: Date = Date(), duration: Double, backtrace: [String] = []) {
        self.timestamp = timestamp
        self.duration = duration
        self.backtrace = backtrace
    }
}

/// Pure hang/ANR detection logic — the threshold comparison, grace-period
/// gating and last-ping tracking are plain date arithmetic.
///
/// Keeping this core free of `DispatchSource` and `Thread.callStackSymbols`
/// makes it trivially testable: tests inject `Date` values directly, and the
/// real timer/stack-symbols are supplied by `HangDetectorRunner` as adapters.
public final class HangDetector {

    /// Minimum main-thread stall (seconds) considered a hang.
    public var threshold: Double

    /// Seconds after `start()` during which no hang is reported, so that
    /// launch-time main-thread work does not produce false positives.
    public var gracePeriod: Double

    private var lastPing = Date()
    private var startedAt: Date?
    private var hangHandler: ((HangEvent) -> Void)?

    public init(threshold: Double = 0.25, gracePeriod: Double = 10) {
        self.threshold = threshold
        self.gracePeriod = gracePeriod
    }

    /// Register a callback invoked once a hang is detected.
    public func onHang(_ handler: @escaping (HangEvent) -> Void) {
        hangHandler = handler
    }

    /// Begin monitoring. `now` is injectable so tests can simulate the
    /// passage of time without real delays.
    public func start(now: Date = Date()) {
        startedAt = now
        lastPing = now
    }

    /// Called from the main thread to record a heartbeat. `now` is injectable
    /// so tests can advance the clock between beats.
    public func mainThreadDidHeartbeat(now: Date = Date()) {
        lastPing = now
    }

    /// Called periodically (e.g. by a `DispatchSource.timer`) to check whether
    /// the main thread has stalled. `now` and `backtrace` are injectable so
    /// tests can assert both the threshold boundary and the reported stack.
    public func watchdogTick(now: Date, backtrace: [String] = []) {
        // Stay silent during the grace period: startup main-thread work would
        // otherwise look like a hang.
        guard let started = startedAt, now.timeIntervalSince(started) > gracePeriod else { return }
        let elapsed = now.timeIntervalSince(lastPing)
        if elapsed >= threshold {
            hangHandler?(HangEvent(timestamp: now, duration: elapsed, backtrace: backtrace))
        }
    }

    /// Stop monitoring and clear state so a later `start()` is clean.
    public func stop() {
        startedAt = nil
    }
}
