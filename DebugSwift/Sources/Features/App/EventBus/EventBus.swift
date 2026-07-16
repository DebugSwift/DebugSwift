//
//  EventBus.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation

// MARK: - #13 Event Timeline (EventBus) — pure core

/// The debug domain an event belongs to.
public enum DebugDomain: String, Equatable, CaseIterable {
    case network
    case performance
    case interface
    case app
    case resources
    case security
}

/// A single debug event collected by the event bus.
public struct DebugEvent: Equatable {
    public let id: UUID
    public let timestamp: Date
    public let domain: DebugDomain
    public let summary: String

    public init(id: UUID = UUID(), timestamp: Date, domain: DebugDomain, summary: String) {
        self.id = id
        self.timestamp = timestamp
        self.domain = domain
        self.summary = summary
    }
}

/// A unified, in-memory event bus collecting events from all debug domains
/// (network, performance, app, etc.) with filtering by domain, text, and
/// time; capacity-bounded.
///
/// The bus is an array of `DebugEvent` structs with append/filter/slice
/// operations — pure data-structure logic. The `Combine`/UI integration is
/// a thin subscriber on top (`EventBusSubscriber`).
public final class EventBus {

    public let capacity: Int
    public private(set) var events: [DebugEvent] = []

    public init(capacity: Int = 5000) {
        self.capacity = capacity
    }

    /// Publish an event, evicting the oldest if at capacity.
    public func publish(_ event: DebugEvent) {
        events.append(event)
        if events.count > capacity {
            events.removeFirst(events.count - capacity)
        }
    }

    /// Filter events by domain.
    public func filtered(by domain: DebugDomain) -> [DebugEvent] {
        events.filter { $0.domain == domain }
    }

    /// Filter events by case-insensitive summary text.
    public func filtered(by text: String) -> [DebugEvent] {
        events.filter { $0.summary.localizedCaseInsensitiveContains(text) }
    }

    /// Events at or after the given date.
    public func eventsSince(_ date: Date) -> [DebugEvent] {
        events.filter { $0.timestamp >= date }
    }

    /// Remove all events.
    public func clear() {
        events.removeAll()
    }
}
