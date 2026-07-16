//
//  FrameDropAdapter.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation
import QuartzCore

// MARK: - #8 Frame Drop Timeline — CADisplayLink adapter

/// UIKit/QuartzCore adapter that feeds `FrameDropTimeline` from a
/// `CADisplayLink`-based FPS sampler.
final class FrameDropAdapter: @unchecked Sendable {

    static let shared = FrameDropAdapter()

    let timeline = FrameDropTimeline()
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

    /// Stop recording.
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
        frameCount = 0
    }

    // MARK: - Private

    @objc
    private func tick(_ link: CADisplayLink) {
        frameCount += 1
        let interval = link.timestamp - lastTimestamp
        guard interval >= 1.0 else { return }
        let fps = Double(frameCount) / interval
        timeline.record(fps: fps, context: nil)
        lastTimestamp = link.timestamp
        frameCount = 0
    }
}
