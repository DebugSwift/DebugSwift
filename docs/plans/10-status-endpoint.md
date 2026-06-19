# Plan 10 — Status Endpoint

**Phase:** 1 · **Priority:** P0 · **Depends on:** [01](./01-foundation-module.md), [05](./05-feature-registry.md), exporters 06–09

## Goal

`GET /status` returns live JSON snapshot of bridge state, all feature flags, device info, launch time. Mirror to `status.json` on every meaningful change.

## Response schema

```json
{
  "bridgeEnabled": true,
  "port": 9999,
  "exportDirectory": "Library/Caches/debugswift-ai",
  "device": {
    "name": "iPhone 16",
    "model": "iPhone",
    "systemVersion": "18.0",
    "bundleId": "com.example.app",
    "appVersion": "1.0"
  },
  "launchTimeMs": 342.5,
  "apnsToken": "abc...",
  "features": {
    "network": { "enabled": true, "options": null },
    "console": { "enabled": true },
    "leaksDetector": { "enabled": true },
    "crashManager": { "enabled": true },
    "performance": { "enabled": true }
  },
  "streams": {
    "network": { "lineCount": 42, "lastTs": "2025-06-16T12:00:00Z" },
    "console": { "lineCount": 128 }
  }
}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/HTTP/Handlers/AIStatusHandler.swift` | Build + encode `AIStatus` |
| `DebugSwift/Sources/AI/Internal/AIStatusWriter.swift` | Overwrite `status.json` atomically |

## Files to modify

| Path | Change |
|------|--------|
| `DebugSwift/Sources/AI/Models/AIStatus.swift` | Extend with `streams`, `apnsToken` |
| `DebugSwift/Sources/Helpers/Managers/APNSTokenManager.swift` | Read token for status (no secret beyond what UI shows) |

## Implementation tasks

- [ ] `AIStatusBuilder.build()` aggregates registry + `LaunchTimeTracker` + `APNSTokenManager`
- [ ] Stream stats from `NDJSONWriter` line counters / last timestamp
- [ ] Call `AIStatusWriter.persist()` after:
  - bootstrap
  - any `setFeature`
  - optional: every 30s heartbeat timer
- [ ] `GET /status` reads fresh build (not stale file)
- [ ] `DebugSwiftAI.status()` returns same struct for in-process use

## Acceptance criteria

- [ ] `curl localhost:9999/status` valid JSON matching schema
- [ ] Toggle network → `features.network.enabled` flips on next GET
- [ ] `status.json` on disk matches HTTP response (modulo timestamp)

## Verification

```bash
curl -s localhost:9999/status | jq '.features.network'
cat "$(xcrun simctl get_app_container booted com.example.app data)/Library/Caches/debugswift-ai/status.json" | jq .
```

## Next

→ [11 — Logs & Features API](./11-logs-features-api.md)
