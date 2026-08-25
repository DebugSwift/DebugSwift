//
//  AgentDebugLogTests.swift
//  DebugSwift
//
//  Tests for the NDJSON aggregation manager described in
//  https://github.com/DebugSwift/skills/blob/main/skills/swift-agent-debug-log/SKILL.md
//

import XCTest
@testable import DebugSwift

final class AgentDebugLogTests: XCTestCase {

    // MARK: - Helpers

    /// Sets `AGENT_DEBUG_LOG_PATH` to a temp file, returning the URL.
    private func withHostLogPath() -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("agent-debug-\(UUID().uuidString).ndjson")
        setenv("AGENT_DEBUG_LOG_PATH", url.path, 1)
        return url
    }

    private func clearEnv() {
        unsetenv("AGENT_DEBUG_LOG_PATH")
        unsetenv("AGENT_DEBUG_SESSION_ID")
    }

    override func tearDown() {
        clearEnv()
        AgentDebugLog.shared.disable()
        super.tearDown()
    }

    // MARK: - Path resolution

    func testCurrentLogPath_usesEnvOverride_whenSet() {
        // Given
        let url = withHostLogPath()

        // Then
        XCTAssertEqual(AgentDebugLog.shared.currentLogPath(), url)
    }

    func testCurrentLogPath_fallsBackToDocuments_whenEnvAbsent() {
        // Given
        clearEnv()

        // When
        let url = AgentDebugLog.shared.currentLogPath()

        // Then
        XCTAssertEqual(url.lastPathComponent, AgentDebugLog.defaultFileName)
        XCTAssertTrue(url.path.contains("/Documents/"))
    }

    // MARK: - NDJSON recording

    func testRecord_writesNDJSONLine_withExpectedSchema() throws {
        // Given
        let url = withHostLogPath()
        setenv("AGENT_DEBUG_SESSION_ID", "sess-123", 1)

        // When
        AgentDebugLog.shared.record(
            kind: .network,
            location: "HTTP.Datasource.swift:42",
            message: "GET /v1/items",
            data: ["status": "200"],
            hypothesisId: "A",
            runId: "pre-fix"
        )

        // Then
        let raw = try String(contentsOf: url, encoding: .utf8)
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: true)
        XCTAssertEqual(lines.count, 1, "expected exactly one NDJSON line")

        let json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(lines[0].utf8)
        ) as? [String: Any])

        XCTAssertEqual(json[AgentDebugLog.Field.sessionId] as? String, "sess-123")
        XCTAssertEqual(json[AgentDebugLog.Field.location] as? String, "HTTP.Datasource.swift:42")
        XCTAssertEqual(json[AgentDebugLog.Field.message] as? String, "GET /v1/items")
        XCTAssertEqual(json[AgentDebugLog.Field.kind] as? String, "network")
        XCTAssertEqual(json[AgentDebugLog.Field.hypothesisId] as? String, "A")
        XCTAssertEqual(json[AgentDebugLog.Field.runId] as? String, "pre-fix")
        XCTAssertNotNil(json[AgentDebugLog.Field.timestamp] as? Int)
        let data = try XCTUnwrap(json[AgentDebugLog.Field.data] as? [String: Any])
        XCTAssertEqual(data["status"] as? String, "200")
    }

    func testRecord_appendsMultipleLines() throws {
        // Given
        let url = withHostLogPath()

        // When
        for i in 0..<5 {
            AgentDebugLog.shared.record(
                kind: .console,
                location: "ConsoleOutput",
                message: "line \(i)"
            )
        }

        // Then
        let raw = try String(contentsOf: url, encoding: .utf8)
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: true)
        XCTAssertEqual(lines.count, 5)
        // Every line must be valid JSON.
        for line in lines {
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(line.utf8)))
        }
    }

    func testRecord_omitsDataField_whenEmpty() throws {
        // Given
        let url = withHostLogPath()

        // When
        AgentDebugLog.shared.record(
            kind: .lifecycle,
            location: "test",
            message: "no data"
        )

        // Then
        let raw = try String(contentsOf: url, encoding: .utf8)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(raw.utf8)
        ) as? [String: Any])
        XCTAssertNil(json[AgentDebugLog.Field.data])
    }

    // MARK: - Enable / Disable lifecycle

    func testEnable_startsCapture_andEmitsLifecycleEntry() throws {
        // Given
        let url = withHostLogPath()
        AgentDebugLog.shared.disable()

        // When
        AgentDebugLog.shared.enable()

        // Then
        XCTAssertTrue(AgentDebugLog.shared.enabled)
        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(raw.contains("agent debug log capture started"))
    }

    func testEnable_isIdempotent_onlyOneLifecycleStartEntry() throws {
        // Given
        let url = withHostLogPath()
        AgentDebugLog.shared.disable()

        // When — enable twice
        AgentDebugLog.shared.enable()
        AgentDebugLog.shared.enable()

        // Then — only one "capture started" entry is written
        let raw = try String(contentsOf: url, encoding: .utf8)
        let startCount = raw.components(separatedBy: "capture started").count - 1
        XCTAssertEqual(startCount, 1)
        XCTAssertTrue(AgentDebugLog.shared.enabled)
    }


    // MARK: - EventBus integration

    func testEnable_subscribesToEventBus() throws {
        // Given
        let url = withHostLogPath()

        // Sanity: direct record works at this path
        AgentDebugLog.shared.record(kind: .event, location: "sanity", message: "SANITY-OK")
        let sanityRaw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(sanityRaw.contains("SANITY-OK"), "direct record must write to env path. sanity=\n\(sanityRaw)")

        // Force a clean enable so we always subscribe a fresh listener.
        AgentDebugLog.shared.disable()
        AgentDebugLog.shared.enable()

        // When — publish a network event
        EventBusSubscriber.shared.publish(DebugEvent(
            timestamp: Date(),
            domain: .network,
            summary: "POST /v2/login"
        ))

        // Then — the event shows up in the NDJSON file
        let data = try Data(contentsOf: url)
        // JSONSerialization escapes forward slashes as \/, so search for
        // a substring without slashes.
        let needle = Data("login".utf8)
        let containsEvent = data.range(of: needle) != nil
        let raw = String(data: data, encoding: .utf8) ?? "<invalid utf8>"
        XCTAssertTrue(containsEvent, "event bus event must be logged. bytes=\(data.count) raw=\n\(raw)")
    }

    func testDisable_unsubscribesFromEventBus() throws {
        // Given
        let url = withHostLogPath()
        AgentDebugLog.shared.enable()
        AgentDebugLog.shared.disable()

        // When — publish after disable
        EventBusSubscriber.shared.publish(DebugEvent(
            timestamp: Date(),
            domain: .network,
            summary: "should-not-appear"
        ))

        // Then — the event is NOT in the NDJSON file
        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(raw.contains("should-not-appear"))
    }

    // MARK: - clear / contents

    func testClear_removesLogFile() throws {
        // Given
        let url = withHostLogPath()
        AgentDebugLog.shared.record(kind: .event, location: "x", message: "y")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // When
        AgentDebugLog.shared.clear()

        // Then
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testContents_returnsFileText() {
        // Given
        let url = withHostLogPath()
        AgentDebugLog.shared.record(kind: .event, location: "loc", message: "hello")

        // Then
        let contents = AgentDebugLog.shared.contents()
        XCTAssertTrue(contents.contains("hello"))
        _ = url
    }

    func testAgentDescription_containsPathAndBundle() {
        // Given
        let url = withHostLogPath()
        let bundleId = Bundle.main.bundleIdentifier ?? "(unknown)"

        // When
        let description = AgentDebugLog.shared.agentDescription

        // Then
        XCTAssertTrue(description.contains(url.path))
        XCTAssertTrue(description.contains(bundleId))
        XCTAssertTrue(description.contains("Capture is ON") || description.contains("Capture is OFF"))
    }
}
