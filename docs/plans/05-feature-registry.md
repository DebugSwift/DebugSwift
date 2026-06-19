# Plan 05 — Feature Registry

**Phase:** 1 · **Priority:** P0 · **Depends on:** [01](./01-foundation-module.md), [04](./04-http-server-core.md)

## Goal

Map string feature IDs (`network`, `interface.grid`, `leaksDetector`) to existing DebugSwift enable/disable APIs. Single source of truth for `POST /features/:id` and `GET /status`.

## ID namespace

```
{swizzleFeature}           → DebugSwiftSwizzleFeature
{tab}.{subfeature}         → UI toggles / toolkit flags
actions/{name}             → side effects (Plan 16)
```

### P0 registry (Phase 1)

| ID | Maps to | Enable | Disable |
|----|---------|--------|---------|
| `network` | `DebugSwiftSwizzleFeature.network` | `FeatureHandling` → `enableNetwork()` | `NetworkHelper.shared.disable()` |
| `console` | `.console` | `enableConsole()` | stop StdoutCapture |
| `leaksDetector` | `.leaksDetector` | `enableLeaksDetector()` | disable leak detector |
| `crashManager` | `.crashManager` | `enableCrashManager()` | inverse |
| `webSocket` | `.webSocket` | `WebSocketMonitor` | `.disable()` |
| `performance` | Performance tab sampler | start `PerformanceToolkit` timer export | stop sampler |

### P1+ (Phase 2, register stubs now)

| ID | API |
|----|-----|
| `interface.grid` | `Interface.Grid` controller / UserDefaults key |
| `interface.touchIndicators` | `UserInterfaceToolkit` |
| `interface.colorize` | UIView swizzle border |
| `performance.hud` | `PerformanceToolkit.isWidgetShown` |
| `floatBall` | `FloatViewManager.show/hide` |
| `oslog` | OSLog capture UserDefaults `debugswift.oslog.capturingEnabled` |

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Features/AIFeatureRegistry.swift` | Registry + dispatch |
| `DebugSwift/Sources/AI/Features/AIFeatureDescriptor.swift` | Metadata: id, type, options schema |
| `DebugSwift/Sources/AI/Features/Handlers/AISwizzleFeatureHandler.swift` | Swizzle features |
| `DebugSwift/Sources/AI/Features/Handlers/AIInterfaceFeatureHandler.swift` | Interface subfeatures (Phase 2) |

## Files to modify

| Path | Change |
|------|--------|
| `DebugSwift/Sources/Settings/FeatureHandling.swift` | Expose `enableX()` / package-private toggles if currently `private` — may need `internal` wrappers |
| `DebugSwift/Sources/AI/DebugSwift.AI.swift` | `setFeature` delegates to registry |

## `setFeature` contract

```json
POST /features/network
{"enabled": true}

POST /features/interface.grid
{"enabled": true, "opacity": 0.3, "color": "#FF0000"}
```

```swift
public static func setFeature(
    _ id: String,
    enabled: Bool,
    options: [String: Any]? = nil
) throws
```

Throws: `unknownFeature`, `invalidOptions`, `mainActorRequired`

## Implementation tasks

- [ ] `AIFeatureRegistry.allDescriptors()` → `GET /features` list
- [ ] Read current state from existing singletons:
  - `NetworkHelper.shared.isNetworkEnable`
  - `DebugSwift.App.shared.disableMethods`
  - UserDefaults keys for UI features
- [ ] All UI mutations on `@MainActor`
- [ ] After toggle, refresh `status.json` and emit `feature.toggled` NDJSON event
- [ ] Respect `setup(disable:)` — registry reports `enabled: false` for disabled-at-launch features; `POST enabled:true` re-enables at runtime

## Acceptance criteria

- [ ] `POST /features/network {"enabled":true}` causes HTTP traffic to appear in network inspector
- [ ] `POST {"enabled":false}` stops new captures
- [ ] Unknown ID → `404` with JSON error

## Verification

```bash
curl -X POST localhost:9999/features/network -H 'Content-Type: application/json' -d '{"enabled":true}'
# trigger network in app
curl localhost:9999/logs/network?tail=5
```

## Next

→ [06](./06-network-export.md) … [11](./11-logs-features-api.md)
