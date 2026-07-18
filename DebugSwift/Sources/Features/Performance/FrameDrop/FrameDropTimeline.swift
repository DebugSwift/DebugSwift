//
//  FrameDropTimeline.swift
//  DebugSwift
//
//  Created by Matheus Gois (Frame Drop Timeline) on 16/07/26.
//

import Foundation

// MARK: - Frame Drop Timeline

/// A single recorded frame-drop event (FPS below the threshold).
public struct FrameDropEvent: Equatable {
    public let timestamp: Date
    public let fps: Double
    public let context: String?

    public init(timestamp: Date, fps: Double, context: String? = nil) {
        self.timestamp = timestamp
        self.fps = fps
        self.context = context
    }
}

/// A capacity-bounded ring buffer of frame-drop events.
///
/// The buffer records only frames below `dropThreshold`, sampled 1-in-N to
/// avoid overhead, and evicts the oldest event when at capacity. `CADisplayLink`
/// is the only iOS adapter — all the data-structure logic is pure.
public final class FrameDropTimeline {

    public let capacity: Int
    public private(set) var events: [FrameDropEvent] = []
    public var dropThreshold: Double
    public let sampleEveryN: Int
    private var counter = 0

    public init(capacity: Int = 5000, dropThreshold: Double = 58, sampleEveryN: Int = 5) {
        self.capacity = capacity
        self.dropThreshold = dropThreshold
        self.sampleEveryN = max(sampleEveryN, 1)
    }

    /// Record a frame sample. Drops frames ≥ `dropThreshold` and samples every
    /// Nth drop. `timestamp` is injectable for testing.
    public func record(fps: Double, timestamp: Date = Date(), context: String? = nil) {
        guard fps < dropThreshold else { return }
        counter += 1
        guard counter.isMultiple(of: sampleEveryN) else { return }
        events.append(FrameDropEvent(timestamp: timestamp, fps: fps, context: context))
        if events.count > capacity {
            events.removeFirst(events.count - capacity)
        }
    }

    /// Clear all recorded events.
    public func clear() {
        events.removeAll()
    }
}
