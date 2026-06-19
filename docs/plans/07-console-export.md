# Plan 07 — Console Export

**Phase:** 1 · **Priority:** P0 · **Depends on:** [03](./03-ndjson-export-layer.md), [05](./05-feature-registry.md)

## Goal

Mirror `print` / `NSLog` capture into `console.jsonl` while preserving existing `StdoutCapture` file log (`{bundleId}-output.log`).

## Hook point

`DebugSwift/Sources/Features/App/Console/Helpers/StdoutCapture.swift`

Function `processCompleteLogLineGlobal(_ line: String)` already:

1. Appends to `StdoutCapture.shared.logUrl`
2. Calls `appendConsoleOutputSafelyGlobal(line)`

Add step 3: `AIConsoleExporter.emit(line:)` when bridge + console feature enabled.

## JSON schema

```json
{
  "ts": "...",
  "feature": "console",
  "event": "line",
  "data": {
    "text": "Hey, DebugSwift is running!",
    "source": "stdout"
  }
}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Export/Exporters/AIConsoleExporter.swift` | Line → AIEvent |

## Implementation tasks

- [ ] Hook in `processCompleteLogLineGlobal` — keep hook minimal (one line call)
- [ ] Strip ANSI color codes if present
- [ ] Cap line length 16KB — truncate with `"truncated": true`
- [ ] Feature gate: `console` swizzle enabled via registry
- [ ] Bridge gate: `AIActivation.isRunning`
- [ ] Existing in-app console UI unchanged — reads same `appendConsoleOutputSafelyGlobal`

## Dual output (doc requirement)

| Sink | Path |
|------|------|
| Legacy | `Library/Caches/{bundleId}-output.log` |
| AI | `Library/Caches/debugswift-ai/console.jsonl` |
| HTTP | `GET /logs/console?tail=50` |

## Acceptance criteria

- [ ] `print("test-ai-console")` in Example → new JSONL line within 1s
- [ ] Legacy log file still receives same line
- [ ] `POST /features/console {"enabled":false}` stops new JSONL lines

## Verification

```bash
curl -s localhost:9999/logs/console?tail=5 | jq .
CONTAINER=$(xcrun simctl get_app_container booted com.example.app data)
tail -1 "$CONTAINER/Library/Caches/debugswift-ai/console.jsonl"
```

## Next

→ [10](./10-status-endpoint.md) · [11](./11-logs-features-api.md)
