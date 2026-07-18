//
//  EventBusSubscriber.swift
//  DebugSwift
//
//  Created by Matheus Gois (Event Timeline) on 16/07/26.
//

import Foundation

// MARK: - Event Timeline

/// A thin subscriber on top of the pure `EventBus`, exposing a closure-based
/// notification API that the existing managers (`NetworkMonitor`,
/// `StdoutCapture`, `HangDetector`, etc.) can publish into and that
/// `EventTimelineViewController` can observe.
final class EventBusSubscriber: @unchecked Sendable {

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
