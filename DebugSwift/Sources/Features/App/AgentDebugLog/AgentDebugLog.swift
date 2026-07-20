//
//  AgentDebugLog.swift
//  DebugSwift
//
//  Aggregates debug data (network, crashes, console, events) into a single
//  NDJSON file an AI agent can pull from the simulator or device.
//  Protocol: https://github.com/DebugSwift/skills/blob/main/skills/swift-agent-debug-log/SKILL.md
//

import Foundation

// MARK: - AgentDebugLog

/// Streams debug data as NDJSON lines to a file an AI agent can read.
/// Disabled by default; activated through the `agentDebugLog` beta feature.
/// Path resolution: `AGENT_DEBUG_LOG_PATH` env var when set, otherwise
/// `Documents/agent-debug.ndjson`.
final class AgentDebugLog: @unchecked Sendable {
    static let shared = AgentDebugLog()

    // MARK: - Configuration

    static let defaultFileName = "agent-debug.ndjson"

    enum Field {
        static let sessionId = "sessionId"
        static let location = "location"
        static let message = "message"
        static let data = "data"
        static let hypothesisId = "hypothesisId"
        static let runId = "runId"
        static let timestamp = "timestamp"
        static let kind = "kind"
    }

    /// Source kind for an aggregated entry.
    enum Kind: String {
        case network
        case crash
        case console
        case stderr
        case event
        case lifecycle
    }

    // MARK: - State

    private let lock = NSLock()
    private nonisolated(unsafe) var isEnabled = false
    private nonisolated(unsafe) var eventListenerToken: UUID?
    private nonisolated(unsafe) var mirrorTimer: DispatchSourceTimer?
    private nonisolated(unsafe) var lastSeenConsoleCount = 0
    private nonisolated(unsafe) var lastSeenStderrCount = 0

    private init() {
        // Singleton.
    }

    // MARK: - Lifecycle

    /// Enables aggregation. Idempotent. Records a lifecycle entry so the
    /// agent can see when capture started.
    func enable() {
        lock.lock()
        if isEnabled {
            lock.unlock()
            return
        }
        isEnabled = true
        lock.unlock()

        record(
            kind: .lifecycle,
            location: "AgentDebugLog.enable",
            message: "agent debug log capture started",
            data: ["path": currentLogPath().path]
        )

        let token = EventBusSubscriber.shared.subscribe { [weak self] event in
            self?.record(
                kind: .event,
                location: "EventBus",
                message: event.summary,
                data: [
                    "domain": event.domain.rawValue,
                    "eventId": event.id.uuidString
                ]
            )
        }
        eventListenerToken = token

        startConsoleMirror()
    }

    /// Disables aggregation. Idempotent. Records a lifecycle entry so the
    /// agent can see when capture stopped.
    func disable() {
        lock.lock()
        if let token = eventListenerToken {
            EventBusSubscriber.shared.unsubscribe(token)
        }
        eventListenerToken = nil
        isEnabled = false
        lock.unlock()

        stopConsoleMirror()

        record(
            kind: .lifecycle,
            location: "AgentDebugLog.disable",
            message: "agent debug log capture stopped"
        )
    }

    var enabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isEnabled
    }

    // MARK: - Path resolution

    /// Resolves the active log path: `AGENT_DEBUG_LOG_PATH` env var when
    /// set and non-empty, otherwise `Documents/agent-debug.ndjson`.
    func currentLogPath() -> URL {
        let env = ProcessInfo.processInfo.environment
        if let path = env["AGENT_DEBUG_LOG_PATH"], !path.isEmpty {
            return URL(fileURLWithPath: path)
        }
        return documentsURL().appendingPathComponent(Self.defaultFileName)
    }

    /// Sandbox-safe Documents directory URL, falling back to NSTemporaryDirectory.
    func documentsURL() -> URL {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        }
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }

    /// Human-readable description shown in the UI and copyable to an AI agent.
    var agentDescription: String {
        let path = currentLogPath().path
        let sessionId = ProcessInfo.processInfo.environment["AGENT_DEBUG_SESSION_ID"] ?? "(none)"
        let bundleId = Bundle.main.bundleIdentifier ?? "(unknown)"
        return """
        DebugSwift Agent Debug Log

        Capture is \(enabled ? "ON" : "OFF").

        Log file:
          \(path)

        Bundle id:
          \(bundleId)

        Agent session id:
          \(sessionId)

        Each line is an NDJSON object with fields:
          sessionId, location, message, data, kind,
          hypothesisId, runId, timestamp (ms since epoch).

        Simulator pull (from the host):
          xcrun simctl get_app_container <device> <bundle-id> data
          # then copy Documents/agent-debug.ndjson
        Or, with XcodeBazelMCP:
          bazel_ios_agent_debug_log_pull { "bundleId": "\(bundleId)" }

        Cursor DEBUG MODE override:
          Set AGENT_DEBUG_LOG_PATH (host path) and
          AGENT_DEBUG_SESSION_ID via launchEnv / SIMCTL_CHILD_*.

        Skill:
          https://github.com/DebugSwift/skills/blob/main/skills/swift-agent-debug-log/SKILL.md
        """
    }

    // MARK: - Recording

    /// Appends a single NDJSON line to the resolved log file.
    func record(
        kind: Kind,
        location: String,
        message: String,
        data: [String: Any] = [:],
        hypothesisId: String = "",
        runId: String = "debugswift"
    ) {
        let env = ProcessInfo.processInfo.environment
        let sessionId = env["AGENT_DEBUG_SESSION_ID"] ?? ""
        var payload: [String: Any] = [
            Field.sessionId: sessionId,
            Field.location: location,
            Field.message: message,
            Field.kind: kind.rawValue,
            Field.hypothesisId: hypothesisId,
            Field.runId: runId,
            Field.timestamp: Int(Date().timeIntervalSince1970 * 1000)
        ]
        if !data.isEmpty {
            payload[Field.data] = data
        }

        guard JSONSerialization.isValidJSONObject(payload),
              let lineData = try? JSONSerialization.data(withJSONObject: payload),
              var line = String(data: lineData, encoding: .utf8) else {
            return
        }
        line += "\n"

        let url = currentLogPath()

        appendLine(line, to: url)
    }

    private static let writeLock = NSLock()

    /// Appends a single UTF-8 line to `url`, creating the file if needed.
    /// Serialized so concurrent callers never interleave or truncate.
    private func appendLine(_ line: String, to url: URL) {
        Self.writeLock.lock()
        defer { Self.writeLock.unlock() }

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            guard let data = line.data(using: .utf8) else { return }
            fileManager.createFile(atPath: url.path, contents: data)
            return
        }

        guard let handle = try? FileHandle(forWritingTo: url) else {
            let fallback = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(Self.defaultFileName)
            if !fileManager.fileExists(atPath: fallback.path) {
                guard let data = line.data(using: .utf8) else { return }
                fileManager.createFile(atPath: fallback.path, contents: data)
                return
            }
            try? line.write(to: fallback, atomically: true, encoding: .utf8)
            if let fallbackHandle = try? FileHandle(forWritingTo: fallback) {
                fallbackHandle.seekToEndOfFile()
                fallbackHandle.write(Data(line.utf8))
                try? fallbackHandle.close()
            }
            return
        }

        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        try? handle.close()
    }

    /// Clears the log file.
    func clear() {
        let url = currentLogPath()
        try? FileManager.default.removeItem(at: url)
    }

    /// Reads the raw NDJSON contents.
    func contents() -> String {
        let url = currentLogPath()
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    // MARK: - Console mirror

    private func startConsoleMirror() {
        let queue = DispatchQueue(label: "com.debugswift.agentdebuglog.mirror", qos: .utility)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            self?.mirrorConsoleOnce()
        }
        timer.resume()
        mirrorTimer = timer
    }

    private func stopConsoleMirror() {
        mirrorTimer?.cancel()
        mirrorTimer = nil
    }

    private func mirrorConsoleOnce() {
        let console = ConsoleOutput.shared.getPrintAndNSLogOutput()
        let stderr = ConsoleOutput.shared.getErrorOutput()

        if console.count > lastSeenConsoleCount {
            let start = max(0, lastSeenConsoleCount)
            for line in console[start..<console.count] {
                record(
                    kind: .console,
                    location: "ConsoleOutput",
                    message: line,
                    data: ["source": "stdout"]
                )
            }
            lastSeenConsoleCount = console.count
        }

        if stderr.count > lastSeenStderrCount {
            let start = max(0, lastSeenStderrCount)
            for line in stderr[start..<stderr.count] {
                record(
                    kind: .stderr,
                    location: "StderrCapture",
                    message: line,
                    data: ["source": "stderr"]
                )
            }
            lastSeenStderrCount = stderr.count
        }
    }
}
