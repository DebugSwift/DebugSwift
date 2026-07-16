//
//  HangDetectorRunner.swift
//  DebugSwift
//
//  Created by Matheus Gois (ANR Detection) on 16/07/26.
//

import Foundation
import UIKit

// MARK: - Hangs / ANR Detection — DispatchSource adapter

/// UIKit/Dispatch adapter that drives the pure `HangDetector`.
///
/// A background `DispatchSource.timer` acts as the watchdog that checks for
/// main-thread stalls, while a fast main-queue timer supplies the heartbeat
/// the detector compares against. Keeping the I/O here leaves the detection
/// logic in `HangDetector` fully testable.
final class HangDetectorRunner: @unchecked Sendable {

    static let shared = HangDetectorRunner()

    private let detector = HangDetector(threshold: 0.25, gracePeriod: 10)
    private var timer: DispatchSourceTimer?
    private var heartbeatTimer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "debugswift.hang-detector")

    private init() {
        // Singleton — no external instances; `shared` is the only entry point.
    }

    /// Recorded hang events, capped to avoid unbounded growth in long-running
    /// debug sessions.
    private(set) var events: [HangEvent] = []
    private let maxEvents = 500

    /// Begin monitoring. Hangs are reported through the `onHang` callback.
    func start() {
        detector.onHang { [weak self] event in
            self?.record(event)
        }
        detector.start()

        // Watchdog: tick on a background queue every `threshold` seconds so
        // the main thread gets a chance to stall before we sample it.
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: detector.threshold)
        timer.setEventHandler { [weak self] in
            self?.detector.watchdogTick(now: Date(), backtrace: Thread.callStackSymbols)
        }
        timer.activate()
        self.timer = timer

        // Heartbeat: ping from the main thread at a faster interval than the
        // threshold so a healthy main thread always refreshes `lastPing`.
        let heartbeat = DispatchSource.makeTimerSource(queue: .main)
        heartbeat.schedule(deadline: .now(), repeating: 0.05)
        heartbeat.setEventHandler { [weak self] in
            self?.detector.mainThreadDidHeartbeat()
        }
        heartbeat.activate()
        self.heartbeatTimer = heartbeat
    }


    /// Stop monitoring and tear down timers.
    func stop() {
        timer?.cancel()
        timer = nil
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
        detector.stop()
    }

    private func record(_ event: HangEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.events.append(event)
            if self.events.count > self.maxEvents {
                self.events.removeFirst(self.events.count - self.maxEvents)
            }
        }
    }
}
