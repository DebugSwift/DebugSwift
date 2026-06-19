# Plan 14 — Interface Visual Features

**Phase:** 2 · **Priority:** P1 · **Depends on:** [05](./05-feature-registry.md)

## Goal

HTTP toggles for visual Interface tab features so agents can enable overlays, then verify via screenshot (Plan 15).

## Feature IDs & existing code

| ID | Existing implementation |
|----|-------------------------|
| `interface.grid` | `DebugSwift/Sources/Features/Interface/Grid/Interface.Grid.Controller.swift` |
| `interface.touchIndicators` | `UserInterfaceToolkit` |
| `interface.colorize` | UIView border swizzle (views feature) |
| `interface.slowAnimations` | `UIView.setAnimationsEnabled` / speed hack |
| `interface.darkMode` | Override `UIUserInterfaceStyle` |
| `performance.hud` | `PerformanceToolkit.isWidgetShown` |
| `floatBall` | `FloatViewManager` |
| `swiftUIRender` | `SwiftUIRenderTracker` (beta) |
| `measurement` | `DebugSwift.Measurement.activate/deactivate` |

## POST body options

```json
// interface.grid
{"enabled": true, "opacity": 0.3, "color": "#FF0000"}

// interface.slowAnimations
{"enabled": true, "speed": 0.25}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Features/Handlers/AIInterfaceFeatureHandler.swift` | Grid, touch, colorize, dark mode |
| `DebugSwift/Sources/AI/Features/Handlers/AIShellFeatureHandler.swift` | floatBall, debugger present/dismiss |

## Files to modify

| Path | Change |
|------|--------|
| `UserInterfaceToolkit.swift` | Expose programmatic toggle if UI-only today |
| `Interface.Grid.Controller.swift` | Accept opacity/color without UI |
| `AIFeatureRegistry.swift` | Register P1 interface IDs |

## Implementation tasks

- [ ] All toggles run on `@MainActor`
- [ ] Persist options in status JSON `features.interface.grid.options`
- [ ] `interface.grid` off → remove overlay window
- [ ] `measurement` → emit `measurement.jsonl` when active (hybrid)
- [ ] `swiftUIRender` → `swiftui-render.jsonl` with render rects
- [ ] Tab visibility: `tabs.network` → maps to `DebugSwiftFeature` hide list (runtime hide is hard — document limitation or mutate `hiddenFeatures`)

## Agent workflow (from doc)

```bash
curl -X POST localhost:9999/features/interface.grid -d '{"enabled":true,"opacity":0.3}'
sleep 0.5  # agent settle — not a code fix, doc only
xcrun simctl io booted screenshot /tmp/grid-on.png
```

## Acceptance criteria

- [ ] Grid visible after POST without opening Interface tab
- [ ] Status reflects grid options
- [ ] Disable restores clean UI

## Verification

```bash
curl -X POST localhost:9999/features/interface.grid -H 'Content-Type: application/json' -d '{"enabled":true}'
./scripts/ai-screenshot.sh /tmp/grid.png
```

## Next

→ [15 — Screenshot Endpoint](./15-screenshot-endpoint.md)
