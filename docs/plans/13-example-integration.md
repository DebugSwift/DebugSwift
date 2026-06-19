# Plan 13 — Example Integration & Docs

**Phase:** 0–1 · **Priority:** P0 · **Depends on:** [02](./02-activation-bootstrap.md), [11](./11-logs-features-api.md), [12](./12-shell-scripts.md)

## Goal

Example app demonstrates AI bridge end-to-end. Developers and Cursor agents can copy Scheme + AppDelegate pattern.

## Files to modify

| Path | Change |
|------|--------|
| `Example/Example/ExampleApp.swift` | `DebugSwiftAI.bootstrap()` after setup |
| `Example/Example.xcodeproj/xcshareddata/xcschemes/Example.xcscheme` | Env: `DEBUGSWIFT_AI=1`, `DEBUGSWIFT_AI_PORT=9999` |
| `Example/README.md` (create if missing) or root `README.md` | Simulator workflow section |

## Scheme configuration

Add to **Run** action:

```xml
<EnvironmentVariables>
   <EnvironmentVariable key="DEBUGSWIFT_AI" value="1" isEnabled="YES"/>
   <EnvironmentVariable key="DEBUGSWIFT_AI_PORT" value="9999" isEnabled="YES"/>
</EnvironmentVariables>
```

Optional separate Scheme **Example (AI)** so default Run stays unchanged — team preference.

## README section (target content)

### AI Automation Quick Start

1. Run Example with AI Scheme (⌘R)
2. `curl localhost:9999/status`
3. Enable network: `curl -X POST localhost:9999/features/network -d '{"enabled":true}'`
4. Trigger network in app
5. `./scripts/ai-tail-logs.sh network --tail 10`
6. Pull from container:

```bash
CONTAINER=$(./scripts/ai-container-path.sh com.example.app)
ls "$CONTAINER/Library/Caches/debugswift-ai/"
```

### simctl launch (no Xcode)

```bash
export SIMCTL_CHILD_DEBUGSWIFT_AI=1
export SIMCTL_CHILD_DEBUGSWIFT_AI_PORT=9999
xcrun simctl launch booted com.example.app
```

## Implementation tasks

- [ ] Resolve Example bundle ID (check `Example/Example/Info.plist` or project settings)
- [ ] Add bootstrap call guarded `#if DEBUG`
- [ ] Verify deep link `debugswift://` still works alongside bridge
- [ ] Add link from `AI_AUTOMATION.md` → `docs/plans/README.md`
- [ ] Optional: Example UI button "Copy AI status URL" for demos

## Smoke test checklist

- [ ] Xcode Run → `curl /status` → `bridgeEnabled: true`
- [ ] Network toggle + log tail
- [ ] Console `print` appears in `console.jsonl`
- [ ] Container path script resolves

## Acceptance criteria

- [ ] New contributor can follow README only and control DebugSwift from terminal in <5 min

## Next

Phase 2 → [14](./14-interface-visual-features.md)
