# Plan 22 — Security Hardening

**Phase:** 1–4 (ongoing) · **Priority:** P0 · **Depends on:** [04](./04-http-server-core.md)

## Goal

Ensure AI bridge cannot ship in Release, cannot leak secrets, and cannot be accidentally exposed on hostile networks.

## Rules (from AI_AUTOMATION.md)

| Rule | Implementation |
|------|----------------|
| `#if DEBUG` only | Entire `Sources/AI/` excluded from Release target |
| Bind `127.0.0.1` default | `AIConfiguration.bindAddress` |
| Optional token | `DEBUGSWIFT_AI_TOKEN` → Bearer on all mutating routes + logs |
| Truncate bodies | 64KB JSONL, 4KB inline preview (Plan 06) |
| Keychain: metadata only | Plan 17 |
| Off by default | No env → no server |

## Files to create / modify

| Path | Change |
|------|--------|
| `DebugSwift/Sources/AI/HTTP/AIAuthMiddleware.swift` | Enforce token on POST, optional on GET |
| `DebugSwift/Sources/AI/Internal/AIConfiguration.swift` | Warn if `0.0.0.0` without token |
| `BUILD.bazel` / Xcode | Release excludes AI sources |
| `.github/workflows/` | CI: grep Release binary for `DebugSwiftAI` symbol — must fail if found |

## Hardening tasks

### Compile-time

- [ ] Verify Release Example archive has no `DebugSwiftAI` strings (`strings` check)
- [ ] SPM conditional compilation flag `DEBUG` matches Xcode

### Runtime

- [ ] Refuse start if Release somehow calls bootstrap (assert + return)
- [ ] Rate limit: max 100 req/s per connection (optional, P2)
- [ ] Max concurrent connections 10

### Data

- [ ] Redact `Authorization` headers in network.jsonl by default
- [ ] Config flag `DEBUGSWIFT_AI_REDACT_HEADERS=1` (default on)
- [ ] Log rotation: when `*.jsonl` > 50MB, rename to `.jsonl.1` (P2)

### Device / LAN (Plan 20)

- [ ] If bind != localhost → require non-empty token
- [ ] Log warning: `Binding to 0.0.0.0 — ensure DEBUGSWIFT_AI_TOKEN is set`

## Threat model (brief)

| Threat | Mitigation |
|--------|------------|
| Release app opens port | DEBUG compile gate |
| Coffee shop Wi‑Fi exposure | localhost default + token on LAN |
| Agent dumps keychain | metadata-only serializer |
| Huge response blows agent context | truncation + `GET /logs/:id` for detail |

## Acceptance criteria

- [ ] Release build: `curl localhost:9999` connection refused (no server)
- [ ] Token set: request without header → 401
- [ ] Network log lines redact `Authorization` values

## Verification

```bash
# Debug build with token
export DEBUGSWIFT_AI_TOKEN=test
curl -s localhost:9999/features/network -X POST -d '{"enabled":true}'  # 401
curl -s -H "Authorization: Bearer test" localhost:9999/status  # 200

# Release archive symbol check
strings Example.app/Example | grep -i DebugSwiftAI && exit 1 || echo OK
```

## Completes

AI automation MVP → production-safe incremental rollout across Phases 1–4.
