# Plan 12 — Shell Scripts

**Phase:** 1 · **Priority:** P0 · **Depends on:** [11](./11-logs-features-api.md)

## Goal

Terminal helpers for agents and developers: tail logs, smoke-test bridge, simulator screenshot wrapper.

## Files to create

| Path | Purpose |
|------|---------|
| `scripts/ai-tail-logs.sh` | Tail NDJSON from HTTP or container file |
| `scripts/ai-smoke-test.sh` | Enable features + assert logs |
| `scripts/ai-screenshot.sh` | simctl + optional in-app (Phase 2) |
| `scripts/ai-container-path.sh` | Resolve simulator app data container |

## `ai-tail-logs.sh`

```bash
#!/usr/bin/env bash
# Usage: ./scripts/ai-tail-logs.sh [stream] [--follow] [--tail N] [--port 9999] [--bundle com.example.app]
```

Behavior:

1. If `curl localhost:$PORT/logs/$STREAM?tail=$N` succeeds → use HTTP (live)
2. Else fallback: `simctl get_app_container` + `tail -f .../debugswift-ai/$STREAM.jsonl`
3. Pipe through `jq -c .` for readability

## `ai-smoke-test.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
PORT=${DEBUGSWIFT_AI_PORT:-9999}
curl -sf "localhost:$PORT/status" | jq -e '.bridgeEnabled == true'
curl -sf -X POST "localhost:$PORT/features/network" -H 'Content-Type: application/json' -d '{"enabled":true}'
# ... assert logs/network returns array
```

Exit non-zero on failure — usable in CI.

## `ai-container-path.sh`

```bash
#!/usr/bin/env bash
BUNDLE=${1:?bundle id}
xcrun simctl get_app_container booted "$BUNDLE" data
```

## `ai-screenshot.sh` (stub until Plan 15)

```bash
#!/usr/bin/env bash
OUT=${1:-/tmp/debugswift-screen.png}
xcrun simctl io booted screenshot "$OUT"
# Optional: --in-app calls curl localhost:9999/screenshot
```

## Implementation tasks

- [ ] `chmod +x` all scripts
- [ ] Use env vars: `DEBUGSWIFT_AI_PORT`, `DEBUGSWIFT_BUNDLE_ID`
- [ ] Document in Example README (Plan 13)
- [ ] Add `scripts/` mention to main README or AI_AUTOMATION.md Related Files

## Acceptance criteria

- [ ] `./scripts/ai-tail-logs.sh network --tail 5` prints JSON lines with app running
- [ ] `./scripts/ai-smoke-test.sh` passes against Example with AI Scheme

## Verification

```bash
./scripts/ai-smoke-test.sh
./scripts/ai-tail-logs.sh console --follow
```

## Next

→ [13 — Example Integration](./13-example-integration.md)
