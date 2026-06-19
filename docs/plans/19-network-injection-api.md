# Plan 19 — Network Injection API

**Phase:** 3 · **Priority:** P1 · **Depends on:** [06](./06-network-export.md), [05](./05-feature-registry.md)

## Goal

Programmatic network mocking: delay, fail, rewrite — via HTTP without UI.

## Existing capabilities

Grep `Network` for injection, threshold, rewrite:

- `DebugSwift.Network` threshold API (`NetworkThresholdTracker`)
- Body editor / injection UI in Network tab
- `EncryptionService` for decrypt toggle (`network.decryption` feature)

## Endpoints

```
POST /actions/network/inject
POST /features/network.decryption
POST /features/network.threshold
DELETE /actions/network/inject/:ruleId
```

## Inject rule schema

```json
{
  "id": "rule-1",
  "match": {
    "urlPattern": "https://api.example.com/*",
    "method": "GET"
  },
  "action": {
    "type": "delay",
    "delayMs": 2000
  }
}
```

Actions: `delay`, `fail` (status code), `rewrite` (status/headers/body), `drop`

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Network/AINetworkInjectionStore.swift` | In-memory rules |
| `DebugSwift/Sources/AI/HTTP/Handlers/AINetworkInjectionHandler.swift` | |
| `DebugSwift/Sources/AI/Export/Exporters/AINetworkInjectionExporter.swift` | `network-injection.jsonl` |

## Files to modify

| Path | Change |
|------|--------|
| `HTTPProtocol.swift` or injection hook | Apply rules before request/response |

## Implementation tasks

- [ ] Audit existing injection implementation — wire AI store to same engine (don't duplicate)
- [ ] Emit `rule.applied` to `network-injection.jsonl`
- [ ] `network.decryption` → `DebugSwift.Network.shared.isDecryptionEnabled`
- [ ] `network.threshold` → POST body `{"limit": 100}`
- [ ] Rule limit: max 50 active rules

## Acceptance criteria

- [ ] Inject delay → network.jsonl shows increased `durationMs`
- [ ] Inject fail → status 500 without server change
- [ ] Clear rules endpoint works

## Verification

```bash
curl -X POST localhost:9999/actions/network/inject -d '{
  "match":{"urlPattern":"*"},
  "action":{"type":"delay","delayMs":3000}
}'
# trigger request, check duration
```

## Next

→ [20](./20-device-parity.md)
