# Plan 20 — Device Parity

**Phase:** 3 · **Priority:** P1 · **Depends on:** [04](./04-http-server-core.md), [15](./15-screenshot-endpoint.md), [11](./11-logs-features-api.md)

## Goal

Same HTTP + NDJSON API works on physical device (Xcode Run, devicectl) — not just Simulator.

## Platform gaps (from AI_AUTOMATION.md)

| Simulator | Device workaround |
|-----------|-------------------|
| `simctl get_app_container` | HTTP GET logs OR App Group |
| `simctl io screenshot` | `GET /screenshot` |
| `127.0.0.1` bridge | LAN IP or USB port forwarding |
| `SIMCTL_CHILD_*` | `DEVICECTL_CHILD_*` or Scheme env |

## Configuration additions

| Env | Purpose |
|-----|---------|
| `DEBUGSWIFT_AI_BIND=0.0.0.0` | Listen on all interfaces (device on Wi‑Fi) |
| `DEBUGSWIFT_AI_PORT=9999` | Same as simulator |
| `DEBUGSWIFT_AI_TOKEN=<secret>` | Required when bind != localhost |

## Files to modify

| Path | Change |
|------|--------|
| `AIConfiguration.swift` | Parse `DEBUGSWIFT_AI_BIND` |
| `AIServer.swift` | Bind address from config |
| `docs/AI_AUTOMATION.md` | Device troubleshooting section |

## Files to create

| Path | Purpose |
|------|---------|
| `scripts/ai-device-launch.sh` | devicectl wrapper with env |
| `docs/plans/device-testing-checklist.md` | Manual QA matrix |

## `ai-device-launch.sh`

```bash
#!/usr/bin/env bash
DEVICE_UDID=${1:?}
BUNDLE=${2:?}
export DEVICECTL_CHILD_DEBUGSWIFT_AI=1
export DEVICECTL_CHILD_DEBUGSWIFT_AI_PORT=9999
export DEVICECTL_CHILD_DEBUGSWIFT_AI_BIND=0.0.0.0
export DEVICECTL_CHILD_DEBUGSWIFT_AI_TOKEN="${DEBUGSWIFT_AI_TOKEN:?set token}"
xcrun devicectl device process launch --device "$DEVICE_UDID" --terminate-existing "$BUNDLE" --console
```

## Testing matrix

| Scenario | iOS 16 | iOS 17+ |
|----------|--------|---------|
| Xcode Scheme env | ✅ | ✅ |
| devicectl launch | ❌ | ✅ |
| curl from Mac to device IP | ✅ with token | ✅ |
| NDJSON via HTTP | ✅ | ✅ |
| Screenshot via `/screenshot` | ✅ | ✅ |
| Pull container file | ❌ | ❌ |

## Implementation tasks

- [ ] Default bind `127.0.0.1` — opt-in `0.0.0.0`
- [ ] Log bound address on startup: `AI bridge listening on http://192.168.x.x:9999`
- [ ] Document Mac firewall + same Wi‑Fi requirement
- [ ] iOS 16 path: Scheme-only, no devicectl — still valid
- [ ] `--console` stdout may include bridge startup log for agents

## Acceptance criteria

- [ ] iPhone on Wi‑Fi: `curl http://<device-ip>:9999/status` with token
- [ ] Screenshot PNG retrievable from device
- [ ] Simulator behavior unchanged

## Verification

```bash
./scripts/ai-device-launch.sh <UDID> com.example.app
# From Mac on same network:
curl -H "Authorization: Bearer $TOKEN" http://192.168.1.x:9999/status
```

## Next

→ [21](./21-mcp-package.md)
