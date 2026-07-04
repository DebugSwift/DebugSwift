import Foundation

public final class DebugSwiftCore: Sendable {
    public static let shared = DebugSwiftCore()

    private let lock = NSLock()
    private nonisolated(unsafe) var events: [DebugEvent] = []

    public init() {}

    public func record(_ event: DebugEvent) {
        lock.lock()
        events.append(event)
        lock.unlock()
    }

    public func snapshot(appName: String, platform: String) -> DebugSnapshot {
        lock.lock()
        let currentEvents = events
        lock.unlock()
        return DebugSnapshot(appName: appName, platform: platform, events: currentEvents)
    }

    public func reset() {
        lock.lock()
        events.removeAll()
        lock.unlock()
    }
}
