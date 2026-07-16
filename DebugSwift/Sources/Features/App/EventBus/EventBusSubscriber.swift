//
//  EventBusSubscriber.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation

// MARK: - #13 Event Timeline — Combine-friendly subscriber

/// A thin subscriber on top of the pure `EventBus`, exposing a closure-based
/// notification API that the existing managers (`NetworkMonitor`,
/// `StdoutCapture`, `HangDetector`, etc.) can publish into and that
/// `EventTimelineViewController` can observe.
final class EventBusSubscriber {

    static let shared = EventBusSubscriber()

    let bus = EventBus()
    private var listeners: [(DebugEvent) -> Void] = []

    private init() {
        // Shared singleton.
    }

    /// Publish an event and notify all listeners.
    func publish(_ event: DebugEvent) {
        bus.publish(event)
        for listener in listeners {
            listener(event)
        }
    }

    /// Register a listener invoked for every published event.
    func subscribe(_ listener: @escaping (DebugEvent) -> Void) {
        listeners.append(listener)
    }

    /// Remove all listeners.
    func unsubscribeAll() {
        listeners.removeAll()
    }
}
