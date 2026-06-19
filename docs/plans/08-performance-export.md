# Plan 08 — Performance Export

**Phase:** 1 · **Priority:** P0 · **Depends on:** [03](./03-ndjson-export-layer.md), [05](./05-feature-registry.md)

## Goal

1 Hz metrics stream (CPU, memory, FPS) to `performance.jsonl` decoupled from UI charts.

## Problem

`PerformanceToolkit` (`DebugSwift/Sources/Features/Performance/Helpers/Performance.Toolkit.swift`) is UI-bound:

- Timer drives widget updates
- Measurements stored in `[CGFloat]` arrays for charts
- No external export today

## Approach

Add **headless sampler** that reuses measurement logic without requiring widget visible.

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Export/Exporters/AIPerformanceSampler.swift` | 1 Hz timer, emits NDJSON |
| `DebugSwift/Sources/AI/Export/Exporters/AIPerformanceMetrics.swift` | Read CPU/mem/FPS from existing helpers |

## Files to modify

| Path | Change |
|------|--------|
| `Performance.Toolkit.swift` | Extract `updateMeasurements()` core into shared `PerformanceMetricsReader` OR call from sampler in parallel (avoid duplicate Timer — prefer single timer fan-out) |

## JSON schema

```json
{
  "feature": "performance",
  "event": "sample",
  "data": {
    "cpuPercent": 12.4,
    "memoryMB": 128.5,
    "fps": 60.0,
    "leakCount": 0
  }
}
```

Optional events: `memory.warning.simulated` (Plan 16 action)

## Implementation tasks

- [ ] Start sampler when `POST /features/performance {"enabled":true}` OR when performance tab swizzle not disabled and bridge starts
- [ ] Reuse `FPSCounter`, existing CPU/memory helpers from toolkit's `updateMeasurements`
- [ ] Include `LaunchTimeTracker.shared` result in first sample + `GET /status`
- [ ] HUD visibility (`performance.hud`) does not gate sampler — doc says metrics in JSONL make screenshot optional
- [ ] Stop timer when feature disabled or bridge stops
- [ ] Disk I/O / battery (P1): separate streams `disk-io.jsonl`, `battery.jsonl` — stub registry entries

## Acceptance criteria

- [ ] ~1 line/sec in `performance.jsonl` while app foregrounded
- [ ] Values roughly match Performance tab UI
- [ ] No retain cycle / main thread blocking

## Verification

```bash
curl -s localhost:9999/logs/performance?tail=3 | jq .
```

## Next

→ [10](./10-status-endpoint.md)
