import DebugSwiftPortable
import Testing

@Test func recordsEventsInSnapshot() throws {
    let core = DebugSwiftCore()
    core.record(DebugEvent(category: "network", message: "GET /health"))

    let snapshot = core.snapshot(appName: "Mini", platform: "Android")

    #expect(snapshot.appName == "Mini")
    #expect(snapshot.platform == "Android")
    #expect(snapshot.events.count == 1)
    #expect(snapshot.events[0].category == "network")
}

@Test func resetClearsEvents() {
    let core = DebugSwiftCore()
    core.record(DebugEvent(category: "network", message: "GET /health"))

    core.reset()

    let snapshot = core.snapshot(appName: "Mini", platform: "Android")
    #expect(snapshot.events.isEmpty)
}

@Test func matchesWildcardPatterns() {
    let matcher = URLPatternMatcher()

    #expect(matcher.matches("https://api.example.com/v1/users", wildcardPattern: "*example.com*/users"))
    #expect(matcher.matches("GET", wildcardPattern: "GET", strategy: .full))
    #expect(!matcher.matches("POST", wildcardPattern: "GET", strategy: .full))
}
