//
//  EventBusTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class EventBusTests: XCTestCase {

    // MARK: - Helpers

    private func makeEvent(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        domain: DebugDomain = .app,
        summary: String = "Test event"
    ) -> DebugEvent {
        DebugEvent(id: id, timestamp: timestamp, domain: domain, summary: summary)
    }

    // MARK: - EventBus: Publish

    func testPublish_storesEvent() {
        // Given
        let bus = EventBus()
        let event = makeEvent(summary: "Stored event")

        // When
        bus.publish(event)

        // Then
        XCTAssertEqual(bus.events.count, 1)
        XCTAssertEqual(bus.events.first, event)
    }

    // MARK: - EventBus: Filtering by domain

    func testFilteredByDomain_returnsOnlyMatching() {
        // Given
        let bus = EventBus()
        bus.publish(makeEvent(domain: .network, summary: "Network event"))
        bus.publish(makeEvent(domain: .performance, summary: "Performance event"))

        // When
        let networkEvents = bus.filtered(by: .network)

        // Then
        XCTAssertEqual(networkEvents.count, 1)
        XCTAssertEqual(networkEvents.first?.domain, .network)
    }

    // MARK: - EventBus: Filtering by text

    func testFilteredByText_caseInsensitive() {
        // Given
        let bus = EventBus()
        bus.publish(makeEvent(summary: "User logged in"))
        bus.publish(makeEvent(summary: "Other event"))

        // When
        let results = bus.filtered(by: "LOGGED")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.summary, "User logged in")
    }

    func testFilteredByText_noMatch_returnsEmpty() {
        // Given
        let bus = EventBus()
        bus.publish(makeEvent(summary: "User logged in"))
        bus.publish(makeEvent(summary: "Other event"))

        // When
        let results = bus.filtered(by: "nonexistent")

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - EventBus: Capacity

    func testEvictsOldestAtCapacity() {
        // Given
        let capacity = 3
        let bus = EventBus(capacity: capacity)
        let base = Date(timeIntervalSince1970: 0)

        // When — publish more than capacity
        for i in 0..<5 {
            bus.publish(makeEvent(
                timestamp: base.addingTimeInterval(TimeInterval(i)),
                summary: "Event \(i)"
            ))
        }

        // Then — only the last 3 remain (oldest evicted)
        XCTAssertEqual(bus.events.count, capacity)
        XCTAssertEqual(bus.events.first?.summary, "Event 2")
        XCTAssertEqual(bus.events.last?.summary, "Event 4")
    }

    // MARK: - EventBus: Events since date

    func testEventsSince_returnsOnlyAfterDate() {
        // Given
        let bus = EventBus()
        let t100 = Date(timeIntervalSince1970: 100)
        let t200 = Date(timeIntervalSince1970: 200)
        let early = makeEvent(timestamp: t100, summary: "Early")
        let late = makeEvent(timestamp: t200, summary: "Late")
        bus.publish(early)
        bus.publish(late)
        let cutoff = Date(timeIntervalSince1970: 150)

        // When
        let since = bus.eventsSince(cutoff)

        // Then
        XCTAssertEqual(since.count, 1)
        XCTAssertEqual(since.first?.summary, "Late")
    }

    // MARK: - EventBus: Clear

    func testClear_removesAllEvents() {
        // Given
        let bus = EventBus()
        bus.publish(makeEvent(summary: "Event 1"))
        bus.publish(makeEvent(summary: "Event 2"))
        XCTAssertEqual(bus.events.count, 2)

        // When
        bus.clear()

        // Then
        XCTAssertTrue(bus.events.isEmpty)
    }

    // MARK: - DebugEvent

    func testDebugEvent_hasUniqueId() {
        // Given
        let event1 = makeEvent()
        let event2 = makeEvent()

        // Then — each event gets a distinct UUID by default
        XCTAssertNotEqual(event1.id, event2.id)
    }

    // MARK: - DebugDomain

    func testDebugDomain_allCases_hasExpectedCount() {
        // Given
        let domains = DebugDomain.allCases

        // Then — six debug domains
        XCTAssertEqual(domains.count, 6)
        XCTAssertTrue(domains.contains(.network))
        XCTAssertTrue(domains.contains(.performance))
        XCTAssertTrue(domains.contains(.interface))
        XCTAssertTrue(domains.contains(.app))
        XCTAssertTrue(domains.contains(.resources))
        XCTAssertTrue(domains.contains(.security))
    }

    // MARK: - EventBusSubscriber: Notifications

    func testPublish_notifiesListeners() {
        // Given
        let subscriber = EventBusSubscriber.shared
        subscriber.unsubscribeAll()
        let event = makeEvent(summary: "Notify me")
        var received: DebugEvent?

        // When
        subscriber.subscribe { received = $0 }
        subscriber.publish(event)

        // Then
        XCTAssertEqual(received, event)

        // Cleanup
        subscriber.unsubscribeAll()
    }

    // MARK: - EventBusSubscriber: Shared singleton

    func testShared_isNotNil() {
        // Then
        XCTAssertNotNil(EventBusSubscriber.shared)
    }

    // MARK: - EventBusSubscriber: Unsubscribe

    func testUnsubscribeAll_removesListeners() {
        // Given
        let subscriber = EventBusSubscriber.shared
        subscriber.unsubscribeAll()
        var callCount = 0
        subscriber.subscribe { _ in callCount += 1 }

        // When
        subscriber.unsubscribeAll()
        subscriber.publish(makeEvent(summary: "After unsubscribe"))

        // Then
        XCTAssertEqual(callCount, 0)

        // Cleanup
        subscriber.unsubscribeAll()
    }
}
