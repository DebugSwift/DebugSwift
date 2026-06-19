# Plan 09 — Leaks & Crashes Export

**Phase:** 1 · **Priority:** P0 · **Depends on:** [03](./03-ndjson-export-layer.md), [05](./05-feature-registry.md)

## Goal

Export memory leak detections and crash reports as NDJSON for AI triage.

## Leaks — hook points

| File | Role |
|------|------|
| `DebugSwift/Sources/Features/Performance/Helpers/Performance.LeakDetector.swift` | Detection engine |
| `DebugSwift/Sources/Features/Performance/Leak/LeaksViewModel.swift` | UI list — hook when new leak added |

## Leaks JSON schema

```json
{
  "feature": "leaks",
  "event": "leak.detected",
  "data": {
    "id": "leak-1",
    "className": "MyViewController",
    "hint": "retain cycle via closure",
    "count": 1
  }
}
```

## Crashes — hook points

| File | Role |
|------|------|
| `DebugSwift/Sources/Features/App/Crash/Main/CrashViewModel.swift` | Crash log list |
| Crash manager swizzle (`FeatureHandling.enableCrashManager`) | New crash capture |

## Crashes JSON schema

```json
{
  "feature": "crashes",
  "event": "crash.recorded",
  "data": {
    "id": "crash-uuid",
    "name": "SIGABRT",
    "reason": "...",
    "stackSummary": ["Frame0", "Frame1"],
    "screenshotRef": "screenshots/crash-uuid.png"
  }
}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Export/Exporters/AILeaksExporter.swift` | |
| `DebugSwift/Sources/AI/Export/Exporters/AICrashesExporter.swift` | Optional auto-screenshot on crash |

## Implementation tasks

- [ ] Register `leaksDetector` and `crashManager` in feature registry
- [ ] Emit on detection — not on UI cell render
- [ ] Crash stack: truncate to 50 frames in JSONL; full in `crashes/<id>.txt` side file
- [ ] Optional: `DebugSwiftAI.captureScreenshot(label: "crash-\(id)")` on crash (Plan 15 dependency — stub ref until then)
- [ ] Thread checker (P1): `thread-violations.jsonl` — separate exporter stub

## Acceptance criteria

- [ ] Induced leak in Example (if exists) → `leaks.jsonl` entry
- [ ] Simulated crash (debug menu) → `crashes.jsonl` entry
- [ ] Features respect enable/disable via POST

## Verification

```bash
curl -s localhost:9999/logs/leaks?tail=10
curl -s localhost:9999/logs/crashes?tail=5
```

## Next

→ [10](./10-status-endpoint.md)
