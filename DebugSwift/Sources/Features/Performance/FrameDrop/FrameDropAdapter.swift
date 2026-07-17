//
//  FrameDropAdapter.swift
//  DebugSwift
//
//  Created by Matheus Gois (Frame Drop Timeline) on 16/07/26.
//

import Foundation
import QuartzCore

// MARK: - Frame Drop Timeline — CADisplayLink adapter

/// UIKit/QuartzCore adapter that feeds `FrameDropTimeline` from a
/// `CADisplayLink`-based FPS sampler.
///
/// Maintains two views of the same sample stream:
/// - ``timeline``: capacity-bounded **drop events** (FPS < threshold), for the timeline screen.
/// - ``fpsHistory``: a rolling window of the **most recent FPS samples** (drop or not),
///   so the Performance tab can render a live sparkline while recording is enabled.
final class FrameDropAdapter: @unchecked Sendable {

    static let shared = FrameDropAdapter()

    let timeline = FrameDropTimeline()

    /// Rolling window of recent per-second FPS samples (drop or not), newest last.
    /// Capped at ``fpsHistoryCapacity`` to bound memory.
    private(set) var fpsHistory: [Double] = []

    /// Max number of FPS samples retained in ``fpsHistory``.
    let fpsHistoryCapacity = 60

    /// Most recently computed per-second FPS, or `nil` before the first sample.
    private(set) var currentFPS: Double?

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount = 0

    private init() {
        // Shared singleton.
    }

    /// Start recording frame drops.
    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    /// Stop recording. Clears the live FPS window; drop events in ``timeline``
    /// are preserved so they remain viewable after recording is paused.
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
        frameCount = 0
        fpsHistory.removeAll()
        currentFPS = nil
    }

    // MARK: - Private

    @objc
    private func tick(_ link: CADisplayLink) {
        frameCount += 1
        let interval = link.timestamp - lastTimestamp
        guard interval >= 1.0 else { return }
        let fps = Double(frameCount) / interval
        currentFPS = fps
        fpsHistory.append(fps)
        if fpsHistory.count > fpsHistoryCapacity {
            fpsHistory.removeFirst(fpsHistory.count - fpsHistoryCapacity)
        }
        timeline.record(fps: fps, context: nil)
        lastTimestamp = link.timestamp
        frameCount = 0
    }
}
