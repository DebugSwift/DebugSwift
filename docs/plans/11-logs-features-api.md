# Plan 11 — Logs & Features HTTP API

**Phase:** 1 · **Priority:** P0 · **Depends on:** [04](./04-http-server-core.md), [05](./05-feature-registry.md), [03](./03-ndjson-export-layer.md), [10](./10-status-endpoint.md)

## Goal

Wire HTTP routes for feature control and log retrieval — the primary agent interface for Phase 1 MVP.

## Endpoints

### `GET /features`

Returns `AIFeatureRegistry.allDescriptors()`:

```json
{
  "features": [
    {
      "id": "network",
      "type": "data",
      "enabled": true,
      "description": "HTTP/WebSocket inspector",
      "optionsSchema": null
    }
  ]
}
```

### `POST /features/:id`

Body: `{"enabled": bool, ...options}`

→ `DebugSwiftAI.setFeature(id, enabled:, options:)`

Response: updated feature state + triggers status refresh

### `GET /logs/:stream`

Query params:

| Param | Behavior |
|-------|----------|
| `tail=N` | Last N lines from ring buffer |
| `since=ISO8601` | Lines with `ts >= since` |
| `filter=substring` | Client-side filter on `data` JSON string (MVP) |

Response:

```json
{
  "stream": "network",
  "lines": [ { /* AIEvent */ }, ... ],
  "truncated": false
}
```

### `GET /logs/:stream/:id`

Single record by `data.id` — scan recent buffer + optional file grep (MVP: buffer only; Phase 3: index)

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/HTTP/Handlers/AIFeaturesHandler.swift` | GET/POST features |
| `DebugSwift/Sources/AI/HTTP/Handlers/AILogsHandler.swift` | GET logs |
| `DebugSwift/Sources/AI/HTTP/Handlers/AILogQuery.swift` | tail/since/filter parser |

## Implementation tasks

- [ ] Register routes in `AIRouter`
- [ ] Validate `stream` against allowlist (prevent path traversal)
- [ ] Max `tail` = 1000
- [ ] `Content-Type: application/json` on all JSON responses
- [ ] `POST` invalid JSON → `400`
- [ ] CORS not required
- [ ] Integration test: enable network → fetch logs (Example UITest or shell script in Plan 12)

## Acceptance criteria

- [ ] Full MVP workflow from AI_AUTOMATION.md works:

```bash
curl -X POST localhost:9999/features/network -d '{"enabled":true}'
curl -s localhost:9999/logs/network?tail=50
```

- [ ] Unknown stream → `404`
- [ ] Unknown feature → `404`

## Verification

See [12 — Shell Scripts](./12-shell-scripts.md) for `ai-smoke-test.sh`

## Next

→ [12](./12-shell-scripts.md) · [13](./13-example-integration.md)
