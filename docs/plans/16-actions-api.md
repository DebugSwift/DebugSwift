# Plan 16 — Actions API

**Phase:** 2 · **Priority:** P1 · **Depends on:** [04](./04-http-server-core.md), [05](./05-feature-registry.md)

## Goal

`POST /actions/:id` triggers side effects without a persistent enabled state.

## Action catalog

| Path | Maps to | NDJSON |
|------|---------|--------|
| `POST /actions/push` | `DebugSwift.PushNotification.simulate(...)` | `push.jsonl` |
| `POST /actions/deeplink` | Open URL in app | `deeplink.jsonl` |
| `POST /actions/location` | Simulated location | `location.jsonl` |
| `POST /actions/performance/memoryWarning` | `UIApplication.shared.perform(...)` | `performance.jsonl` event |
| `POST /actions/network/clear` | `DebugSwift.Network.shared.clearAllNetworkData()` | — |
| `POST /actions/debugger/present` | `DebugSwift.App.presentDebugger()` | screenshot recommended |
| `POST /actions/debugger/dismiss` | Dismiss debugger VC | — |
| `POST /actions/docRecorder/start` | P2 — stub 501 | — |
| `POST /actions/viewDebugger/open` | P2 — stub 501 | — |

## Request examples

```json
POST /actions/push
{"title": "Test", "body": "Hello AI", "delay": 0}

POST /actions/deeplink
{"url": "myapp://path?x=1"}

POST /actions/location
{"latitude": 37.7749, "longitude": -122.4194}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/HTTP/Handlers/AIActionsHandler.swift` | Route + validate body |
| `DebugSwift/Sources/AI/Actions/AIActionRegistry.swift` | Id → closure |
| `DebugSwift/Sources/AI/Export/Exporters/AIPushExporter.swift` | |
| `DebugSwift/Sources/AI/Export/Exporters/AIDeeplinkExporter.swift` | |

## Existing APIs

| File | API |
|------|-----|
| `DebugSwift.PushNotification.swift` | `simulate()` |
| `DeepLink.Models.swift` | URL handling |
| Location feature | `FeatureHandling.enableLocation()` + simulator |
| `DebugSwift.App.swift` | `presentDebugger()` |
| `DebugSwift.Network.swift` | `clearAllNetworkData()` |

## Implementation tasks

- [ ] Separate namespace from features — actions are verbs
- [ ] Validate URLs before deeplink (scheme allowlist optional)
- [ ] Push simulation requires feature enabled or auto-enable for action
- [ ] Emit NDJSON `action.completed` with payload echo
- [ ] Custom host actions (P1): `GET /custom/info`, `POST /custom/actions/:id` via `DebugSwift.App.shared.customAction` reflection — fragile, document

## Acceptance criteria

- [ ] `POST /actions/push` shows notification in simulator
- [ ] `POST /actions/deeplink` triggers Example deep link handler
- [ ] `POST /actions/network/clear` empties network log stream

## Verification

```bash
curl -X POST localhost:9999/actions/push -H 'Content-Type: application/json' \
  -d '{"title":"AI","body":"test"}'
curl -s localhost:9999/logs/push?tail=1 | jq .
```

## Next

→ [17](./17-resources-endpoints.md)
