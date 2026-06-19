# Plan 04 — HTTP Server Core

**Phase:** 1 · **Priority:** P0 · **Depends on:** [01](./01-foundation-module.md), [02](./02-activation-bootstrap.md)

## Goal

Minimal embedded HTTP server in DEBUG builds: bind localhost, route requests, JSON responses, optional token auth. No business logic — delegates to handlers added in later plans.

## Technology choice

| Option | Pros | Cons |
|--------|------|------|
| **Network.framework `NWListener`** | No deps, Apple-native | Manual HTTP parsing |
| **SwiftNIO** | Full HTTP | Heavy dependency |
| **GCD + socket** | Tiny | Reinventing wheel |

**Recommendation:** `NWListener` + lightweight HTTP request parser (or reuse if project already has one — grep shows none). Keep dependency-free.

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/HTTP/AIServer.swift` | Start/stop listener |
| `DebugSwift/Sources/AI/HTTP/AIHTTPRequest.swift` | Parse method, path, query, body |
| `DebugSwift/Sources/AI/HTTP/AIHTTPResponse.swift` | Status, headers, JSON body |
| `DebugSwift/Sources/AI/HTTP/AIRouter.swift` | Route table |
| `DebugSwift/Sources/AI/HTTP/AIAuthMiddleware.swift` | `DEBUGSWIFT_AI_TOKEN` Bearer check |

## Bind address

| Environment | Bind |
|-------------|------|
| Simulator default | `127.0.0.1:<port>` — Mac reaches via port forward |
| Device on LAN | Config `DEBUGSWIFT_AI_BIND=0.0.0.0` (opt-in, Plan 20) |

## Route table (stubs → filled in Plan 11+)

| Method | Path | Handler |
|--------|------|---------|
| GET | `/status` | Plan 10 |
| GET | `/features` | Plan 05 |
| POST | `/features/:id` | Plan 05 |
| GET | `/logs/:stream` | Plan 11 |
| GET | `/logs/:stream/:id` | Plan 06 |
| GET | `/screenshot` | Plan 15 |
| POST | `/actions/:id` | Plan 16 |
| GET | `/resources/*` | Plan 17 |

## Implementation tasks

- [ ] `AIServer.start(port:)` called from `bootstrap()`
- [ ] `AIServer.stop()` on app terminate (optional `NSNotification` observer)
- [ ] Parse query: `tail`, `since`, `filter` for logs endpoint
- [ ] CORS: not needed (local agents only)
- [ ] Max body size 1 MB for POST
- [ ] Return `401` if token configured and `Authorization: Bearer <token>` missing/wrong
- [ ] Return `404` unknown routes, `405` wrong method
- [ ] JSON error envelope: `{"error": "...", "code": "feature_not_found"}`
- [ ] Log server start to os_log category `DebugSwift.AI` (not NDJSON — meta)

## Threading

- Accept connections on listener queue
- Feature toggles that touch UI → `DispatchQueue.main.async`
- Log reads from ring buffer — lock-free or serial queue

## Acceptance criteria

- [ ] `curl localhost:9999/status` returns `200` JSON (even if empty)
- [ ] Wrong token → `401`
- [ ] Release build: no listener code compiled

## Verification

```bash
curl -v localhost:9999/status
curl -v -H "Authorization: Bearer wrong" localhost:9999/status  # when token set
```

## Next

→ [05 — Feature Registry](./05-feature-registry.md) · [10 — Status](./10-status-endpoint.md) · [11 — Logs API](./11-logs-features-api.md)
