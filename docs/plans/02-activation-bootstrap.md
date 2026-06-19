# Plan 02 — Activation Bootstrap

**Phase:** 1 · **Priority:** P0 · **Depends on:** [01](./01-foundation-module.md)

## Goal

Start the AI bridge automatically when the host app opts in via environment variable, launch argument, or explicit `DebugSwiftAI.bootstrap()` call.

## Activation matrix

| Method | Detection | Simulator | Device |
|--------|-----------|-----------|--------|
| Env `DEBUGSWIFT_AI=1` | `ProcessInfo.processInfo.environment["DEBUGSWIFT_AI"] == "1"` | `SIMCTL_CHILD_DEBUGSWIFT_AI=1` | `DEVICECTL_CHILD_*` or Scheme |
| Launch arg `-DebugSwiftAI` | `ProcessInfo.processInfo.arguments.contains("-DebugSwiftAI")` | `simctl launch ... -- -DebugSwiftAI` | Scheme Arguments |
| Programmatic | `DebugSwiftAI.bootstrap()` in `AppDelegate` | Always available in DEBUG | Same |

**Default:** bridge OFF. No behavior change for existing integrators.

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Internal/AIActivation.swift` | Parses env/args, idempotent flag |

## Files to modify

| Path | Change |
|------|--------|
| `DebugSwift/Sources/AI/DebugSwift.AI.swift` | Wire `bootstrap()` |
| `DebugSwift/Sources/Settings/DebugSwift.swift` | Optional: call `DebugSwiftAI.bootstrap()` at end of `setup()` behind `#if DEBUG` — **or** require explicit call in host app (prefer explicit in Example) |
| `Example/Example.xcodeproj/xcshareddata/xcschemes/Example.xcscheme` | Add env vars for local dev |
| `Example/Example/ExampleApp.swift` | `DebugSwiftAI.bootstrap()` after `setup()` |

## Implementation tasks

- [ ] `AIActivation.shouldStart` — true if env OR launch arg OR forced programmatic
- [ ] `bootstrap()` is idempotent — second call no-ops with debug log
- [ ] On start:
  1. Create export directories (Plan 01)
  2. Start HTTP server (Plan 04) on configured port
  3. Register NDJSON writers (Plan 03 hooks, no-op until feature exporters attach)
  4. Write initial `status.json`
- [ ] On `setup(disable:)` — bridge still starts but respects disabled swizzles; feature registry reflects `DebugSwift.App.shared.disableMethods`
- [ ] Document Scheme env vars in Example README (Plan 13)

## Example Scheme snippet

```xml
<EnvironmentVariables>
   <EnvironmentVariable key="DEBUGSWIFT_AI" value="1" isEnabled="YES"/>
   <EnvironmentVariable key="DEBUGSWIFT_AI_PORT" value="9999" isEnabled="YES"/>
</EnvironmentVariables>
```

## Example AppDelegate

```swift
debugSwift.setup(enableBetaFeatures: [...])
#if DEBUG
DebugSwiftAI.bootstrap()
#endif
debugSwift.show()
```

## Acceptance criteria

- [ ] Launch Example with Scheme env → `curl localhost:9999/status` responds (after Plan 04)
- [ ] Launch without env → no server listening, zero perf impact
- [ ] `simctl launch` with `SIMCTL_CHILD_DEBUGSWIFT_AI=1` works

## Verification

```bash
export SIMCTL_CHILD_DEBUGSWIFT_AI=1
export SIMCTL_CHILD_DEBUGSWIFT_AI_PORT=9999
xcrun simctl launch booted com.example.app  # replace bundle id
curl -s localhost:9999/status | jq .
```

## Next

→ [03 — NDJSON Export Layer](./03-ndjson-export-layer.md) · [04 — HTTP Server](./04-http-server-core.md)
