# Plan 03 — NDJSON Export Layer

**Phase:** 1 · **Priority:** P0 · **Depends on:** [01](./01-foundation-module.md)

## Goal

Shared append-only JSONL writer with a common envelope schema. Every data feature (network, console, performance, …) calls one API instead of rolling its own file I/O.

## Envelope schema (from AI_AUTOMATION.md)

```json
{
  "ts": "2025-06-16T12:00:00.000Z",
  "feature": "network",
  "event": "request.completed",
  "data": { }
}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Export/NDJSONWriter.swift` | Thread-safe append per stream |
| `DebugSwift/Sources/AI/Export/AIEvent.swift` | `struct AIEvent: Codable` |
| `DebugSwift/Sources/AI/Export/AIEventEncoder.swift` | ISO8601 dates, compact JSON line |
| `DebugSwift/Sources/AI/Export/AIStreamRegistry.swift` | Named streams → file URLs |

## Stream registry

| Stream ID | File |
|-----------|------|
| `network` | `network.jsonl` |
| `websocket` | `websocket.jsonl` |
| `console` | `console.jsonl` |
| `oslog` | `oslog.jsonl` |
| `performance` | `performance.jsonl` |
| `leaks` | `leaks.jsonl` |
| `crashes` | `crashes.jsonl` |
| `push` | `push.jsonl` |
| `deeplink` | `deeplink.jsonl` |

## Implementation tasks

- [ ] `NDJSONWriter` uses dedicated serial `DispatchQueue` per stream (avoid cross-stream blocking)
- [ ] `append(event: AIEvent, stream: String)` — encode one line + `\n`, append atomically via `FileHandle`
- [ ] Rotate/truncate policy: **none for MVP** — document max file size in Plan 22
- [ ] `bodyTruncationLimit` constant `65536` — used by network exporter (Plan 06)
- [ ] In-memory ring buffer (optional, 500 lines) per stream for `GET /logs?tail=N` without full file read
- [ ] `AIStreamRegistry.shared.writer(for: "network")` singleton accessors
- [ ] Unit-testable: inject temp directory URL in `#if DEBUG` tests

## API sketch

```swift
enum AIExport {
    static func emit(feature: String, event: String, data: [String: Any]) {
        let payload = AIEvent(ts: .now, feature: feature, event: event, data: data)
        NDJSONWriter.shared.append(payload, stream: feature)
    }
}
```

Use `JSONSerialization` or `Codable` with `AnyCodable` helper for `data` dict — prefer small `Codable` structs per event type where possible.

## Dual output contract

Every `emit()` must:

1. Append to `.jsonl` file
2. Push to in-memory ring (for HTTP tail)
3. **Not** block main thread — network/console hooks may fire on background queues

## Acceptance criteria

- [ ] Two rapid `emit` calls produce two valid JSON lines parseable by `jq -c .`
- [ ] Concurrent emits from network thread don't corrupt lines
- [ ] File appears at `exportDirectory/network.jsonl` when stream is `network`

## Verification

```bash
CONTAINER=$(xcrun simctl get_app_container booted <bundle> data)
tail -3 "$CONTAINER/Library/Caches/debugswift-ai/network.jsonl" | jq .
```

## Next

→ Feature-specific exporters: [06](./06-network-export.md) … [09](./09-leaks-crashes-export.md)
