# Plan 06 — Network Export

**Phase:** 1 · **Priority:** P0 · **Depends on:** [03](./03-ndjson-export-layer.md), [05](./05-feature-registry.md)

## Goal

Emit structured NDJSON for every HTTP/WebSocket request captured by existing swizzles. Truncate large bodies; offer full body via `GET /logs/network/:id/body`.

## Hook points (existing code)

| File | Hook |
|------|------|
| `DebugSwift/Sources/Features/Network/Helpers/HTTPProtocol.swift` | Request/response completion |
| `DebugSwift/Sources/Features/Network/Helpers/NetworkHelper.swift` | Enable gate |
| `DebugSwift/Sources/Features/Network/Models/HTTP.Model.swift` | Source model (`HttpModel`) |
| `DebugSwift/Sources/Features/Network/Main/Network.ViewModel.swift` | May already aggregate — avoid duplicate emits |

## JSON `data` schema (per event)

```json
{
  "id": "req-abc123",
  "method": "GET",
  "url": "https://api.example.com/users",
  "status": 200,
  "durationMs": 142,
  "requestHeaders": {},
  "responseHeaders": {},
  "requestBodyRef": "bodies/req-abc123-req.bin",
  "responseBodyRef": "bodies/req-abc123-res.bin",
  "requestBodyTruncated": false,
  "responseBodyTruncated": true,
  "source": "urlsession"
}
```

Events: `request.started`, `request.completed`, `request.failed`

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Export/Exporters/AINetworkExporter.swift` | HttpModel → AIEvent |
| `DebugSwift/Sources/AI/Export/BodyStore.swift` | Spill bodies >64KB to `bodies/` dir |

## Implementation tasks

- [ ] Add `AINetworkExporter.shared.record(model: HttpModel, phase:)` called from HTTPProtocol completion path
- [ ] Guard: only emit when `NetworkHelper.shared.isNetworkEnable` AND AI bridge active
- [ ] Map `HttpModel.id` (index-based today) → stable `req-<uuid>` stored on model or side table
- [ ] Truncate inline body preview to 4KB in JSONL; flag `truncated: true`
- [ ] Store full body in `debugswift-ai/bodies/<id>-req.bin` when AI enabled
- [ ] `GET /logs/network/:id` returns full metadata + inline body or ref
- [ ] WebSocket frames → `websocket.jsonl` with `feature: "websocket"` (same exporter, different stream)
- [ ] WKWebView (P1): add `"source": "webview"` field — hook `WKWebViewNetworkMonitor`

## Redesign notes (from doc)

`HttpModel` is UI-oriented (`statusCode: String?`, `index: Int`). Exporter layer must normalize:

```swift
func normalize(_ model: HttpModel) -> NetworkAIRecord { ... }
```

Do **not** refactor `HttpModel` in Phase 1 — adapter only.

## Acceptance criteria

- [ ] Example app network call → line in `network.jsonl`
- [ ] `curl localhost:9999/logs/network?tail=1` matches file
- [ ] 100KB response → truncated in JSONL, full in body store

## Verification

```bash
# In Example, tap a network demo button
CONTAINER=$(xcrun simctl get_app_container booted com.example.app data)
tail -1 "$CONTAINER/Library/Caches/debugswift-ai/network.jsonl" | jq .
curl -s "localhost:9999/logs/network/$(jq -r .data.id)" | jq .
```

## Next

→ [11 — Logs API](./11-logs-features-api.md)
