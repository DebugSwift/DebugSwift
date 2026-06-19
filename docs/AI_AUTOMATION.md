# DebugSwift AI Automation

> Main design doc for making every DebugSwift feature controllable and observable by AI agents (Cursor, MCP, terminal scripts, CI).

> **Epic branch:** All implementation (Plans 01–22) merges into [`epic/v3`](./plans/README.md#integration-branch-epicv3) → `develop` when complete.

## Goal

An AI agent should be able to:

1. **Enable / disable** any DebugSwift feature from the terminal (without tapping the UI)
2. **Read structured logs** for data features (network, console, crashes, performance metrics)
3. **Capture screenshots** for visual features (grid overlay, view debugger, touch indicators, etc.)
4. Work on **Simulator** and, where possible, on **physical devices** running from Xcode

Today DebugSwift is fully in-process and UI-driven. This doc defines the bridge layer to add on top of existing APIs.

---

## Table of Contents

- [Current State](#current-state)
- [Platform Matrix: Simulator vs Device](#platform-matrix-simulator-vs-device)
- [Proposed Architecture](#proposed-architecture)
- [Terminal Workflows (Today vs Target)](#terminal-workflows-today-vs-target)
- [Feature Inventory](#feature-inventory)
- [Visual Features & Screenshots](#visual-features--screenshots)
- [Log Formats & Export Paths](#log-formats--export-paths)
- [Implementation Phases](#implementation-phases)
- [CLI Reference (Target)](#cli-reference-target)
- [MCP Integration](#mcp-integration)
- [Security & Constraints](#security--constraints)

---

## Current State

### What exists today

| Capability | Status |
|---|---|
| Programmatic setup (`setup`, `hideFeatures`, `disable`) | ✅ Public API |
| Per-feature singleton APIs (`DebugSwift.Network`, `.Performance`, etc.) | ✅ Partial |
| In-memory data stores (HTTP models, console, leaks, etc.) | ✅ Internal |
| UI toggles (UserDefaults keys like `debugswift.oslog.capturingEnabled`) | ✅ UI only |
| Terminal / CLI bridge | ❌ Not built |
| Launch-argument / env-var feature flags | ❌ Not built |
| Structured log export for AI | ❌ Not built |
| Remote HTTP/MCP server | ❌ Not built |

### Entry points (library)

| File | Role |
|---|---|
| `DebugSwift/Sources/Settings/DebugSwift.swift` | Main public API |
| `DebugSwift/Sources/Settings/FeatureHandling.swift` | Swizzle orchestration |
| `DebugSwift/Sources/Base/FeatureBase.swift` | Feature enums |
| `DebugSwift/Sources/Settings/DebugSwift.*.swift` | Per-domain APIs |

### Feature enums

```swift
// Tabs (hide from UI)
DebugSwiftFeature: network | performance | interface | resources | app

// Instrumentation (disable swizzling)
DebugSwiftSwizzleFeature: network | webSocket | wkWebView | location | views
  | crashManager | leaksDetector | console | pushNotifications | swiftUIRender

// Beta
DebugSwiftBetaFeature: swiftUIRenderTracking | networkSessionPersistence
```

---

## Platform Matrix: Simulator vs Device

### Simulator — full support (recommended for AI)

| Capability | Tool | Notes |
|---|---|---|
| Launch with env vars | `SIMCTL_CHILD_*` prefix | Passed to app process |
| Launch with args | `xcrun simctl launch booted <bundle> --arg value` | Args arrive in `ProcessInfo` |
| Screenshot (full screen) | `xcrun simctl io booted screenshot out.png` | Includes overlays (grid, HUD, float ball) |
| UI hierarchy snapshot | XcodeBuild MCP `snapshot_ui` / `screenshot` | Semantic element refs for automation |
| Read app sandbox files | `xcrun simctl get_app_container booted <bundle> data` | Pull NDJSON logs from container |
| Stream system logs | `xcrun simctl spawn booted log stream --predicate ...` | OSLog, crashes |
| Open URL (deep link trigger) | `xcrun simctl openurl booted debugswift://...` | Requires host app scheme + bridge handler |
| Port forwarding | Simulator shares Mac network | Local HTTP bridge on `127.0.0.1:<port>` reachable from Mac |

**Example — launch with AI bridge enabled:**

```bash
export SIMCTL_CHILD_DEBUGSWIFT_AI=1
export SIMCTL_CHILD_DEBUGSWIFT_AI_PORT=9999
xcrun simctl launch booted com.example.app
```

**Example — pull exported logs:**

```bash
CONTAINER=$(xcrun simctl get_app_container booted com.example.app data)
cat "$CONTAINER/Library/Caches/debugswift-ai/network.jsonl"
```

**Example — screenshot for visual verification:**

```bash
xcrun simctl io booted screenshot /tmp/debugswift-screen.png
# or via XcodeBuild MCP: screenshot tool
```

### Physical Device (Xcode Run) — partial support

| Capability | Tool | iOS version | Notes |
|---|---|---|---|
| Launch with env vars | `DEVICECTL_CHILD_*` prefix + `devicectl` | 17+ | Requires `xcrun devicectl device process launch` |
| Capture stdout/stderr | `devicectl ... launch --console` | 17+, Xcode 16+ | Routes app output to terminal |
| Screenshot | No native `devicectl` screenshot | — | Use QuickTime, `idevicescreenshot` (libimobiledevice), or in-app export |
| Read sandbox files | Harder than simulator | — | No `get_app_container` equivalent; need App Group + Files sharing, or HTTP bridge |
| LLDB from Xcode | `po`, `expr` | All | Manual, not scriptable for agents unless debug server exposed |
| Network bridge | Local HTTP if Mac can reach device IP | — | Device and Mac on same LAN; bridge binds `0.0.0.0` |

**Example — launch on device with env vars (iOS 17+):**

```bash
export DEVICECTL_CHILD_DEBUGSWIFT_AI=1
export DEVICECTL_CHILD_DEBUGSWIFT_AI_PORT=9999
xcrun devicectl device process launch \
  --device <DEVICE_UDID> \
  --terminate-existing \
  com.example.app
```

**Example — capture stdout while running on device (Xcode 16+):**

```bash
xcrun devicectl device process launch \
  --device <DEVICE_UDID> \
  --console \
  com.example.app
```

### Physical Device — limitations

| Limitation | Workaround |
|---|---|
| iOS 16 and below — no `devicectl` | Use `ios-deploy`, Xcode GUI, or in-app HTTP bridge started at launch |
| No `simctl get_app_container` | Export logs via HTTP bridge or shared App Group container |
| Screenshot from terminal | In-app `DebugSwift.AI.captureScreenshot()` writes PNG to export dir; pull via HTTP GET |
| Sandboxed file access from Mac | HTTP bridge is the primary path for device AI integration |
| Running from Xcode (⌘R) | Env vars can be set in Scheme → Run → Arguments → Environment Variables; same `DEBUGSWIFT_AI_*` keys |

### Verdict

| Environment | AI control | AI logs | AI screenshots |
|---|---|---|---|
| **Simulator + terminal** | ✅ Full (env + HTTP + simctl) | ✅ File pull + HTTP | ✅ `simctl io screenshot` + MCP |
| **Device + devicectl (iOS 17+)** | ✅ Env vars | ⚠️ HTTP bridge or `--console` | ⚠️ In-app export or QuickTime |
| **Device + Xcode Run (⌘R)** | ✅ Scheme env vars | ⚠️ HTTP bridge | ⚠️ In-app export |
| **Device iOS 16** | ⚠️ Scheme args only | ⚠️ HTTP bridge only | ⚠️ In-app export |

**Recommendation:** Build the HTTP + NDJSON export bridge first — it works on simulator and device with the same API.

---

## Proposed Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  AI Agent (Cursor / MCP / shell script)                     │
└────────────┬───────────────────────────────┬────────────────┘
             │ HTTP/JSON                      │ simctl / devicectl
             ▼                                ▼
┌────────────────────────┐         ┌──────────────────────────┐
│  DebugSwift.AI Bridge  │         │  Platform tools           │
│  (in-app, DEBUG only)  │         │  screenshot, file pull,   │
│                        │         │  launch env vars          │
│  GET  /status          │         └──────────────────────────┘
│  POST /features/{id}   │
│  GET  /logs/{stream}   │
│  GET  /screenshot       │
│  POST /actions/{id}    │
└────────────┬───────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│  Existing DebugSwift internals                              │
│  NetworkHelper, StdoutCapture, LeakDetector, UserInterface… │
└────────────────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│  Export layer (always-on when AI enabled)                  │
│  Library/Caches/debugswift-ai/*.jsonl                      │
│  Library/Caches/debugswift-ai/screenshots/*.png            │
└────────────────────────────────────────────────────────────┘
```

### New module: `DebugSwift.AI`

Planned public surface:

```swift
public enum DebugSwiftAI {
    /// Start bridge if DEBUGSWIFT_AI=1 or launch arg -DebugSwiftAI
    public static func bootstrap()

    /// Enable/disable any feature by string id (maps to existing APIs)
    public static func setFeature(_ id: String, enabled: Bool) throws

    /// Snapshot current state as JSON (for GET /status)
    public static func status() -> AIStatus

    /// Append-only export paths
    public static var exportDirectory: URL

    /// Capture key window → PNG in export dir
    public static func captureScreenshot(label: String?) -> URL
}
```

### Activation

| Method | Simulator | Device |
|---|---|---|
| Environment variable `DEBUGSWIFT_AI=1` | `SIMCTL_CHILD_DEBUGSWIFT_AI=1` | `DEVICECTL_CHILD_DEBUGSWIFT_AI=1` or Xcode Scheme |
| Launch argument `-DebugSwiftAI` | `simctl launch ... -- -DebugSwiftAI` | Scheme Arguments |
| Programmatic (always in DEBUG) | `DebugSwiftAI.bootstrap()` in Example app | Same |

### Dual output strategy

Every data feature writes to **both**:

1. **In-app HTTP API** — live queries, toggles, actions
2. **NDJSON files** — tail-friendly, pull via `simctl get_app_container`, gitignore-friendly

---

## Terminal Workflows (Today vs Target)

### Today (without bridge — limited)

```bash
# 1. Build & run Example on simulator (XcodeBuild MCP or xcodebuild)
# 2. Screenshot only — no feature control
xcrun simctl io booted screenshot /tmp/screen.png

# 3. Console log file (if console swizzle enabled) — existing StdoutCapture
CONTAINER=$(xcrun simctl get_app_container booted com.example.app data)
cat "$CONTAINER/Library/Caches/com.example.app-output.log" 2>/dev/null || true
```

Setup is only controllable at compile/launch time via Swift code in `AppDelegate`/`ExampleApp.swift`:

```swift
debugSwift.setup(disable: [.network])  // must change code & rebuild
```

### Target (with `DebugSwift.AI` bridge)

```bash
# Enable AI bridge at launch
export SIMCTL_CHILD_DEBUGSWIFT_AI=1
export SIMCTL_CHILD_DEBUGSWIFT_AI_PORT=9999
xcrun simctl launch booted com.example.app

# Enable network logging
curl -s -X POST localhost:9999/features/network \
  -H 'Content-Type: application/json' \
  -d '{"enabled": true}'

# Tail network logs (NDJSON)
curl -s localhost:9999/logs/network?tail=50

# Or from container file
CONTAINER=$(xcrun simctl get_app_container booted com.example.app data)
tail -f "$CONTAINER/Library/Caches/debugswift-ai/network.jsonl"

# Enable grid overlay + screenshot
curl -s -X POST localhost:9999/features/interface.grid -d '{"enabled": true}'
xcrun simctl io booted screenshot /tmp/grid-overlay.png

# In-app screenshot (includes DebugSwift UI if presented)
curl -s localhost:9999/screenshot -o /tmp/in-app.png
```

---

## Feature Inventory

Legend:

| Column | Meaning |
|---|---|
| **AI type** | `data` = JSON/logs only · `visual` = needs screenshot · `action` = trigger side-effect · `hybrid` = both |
| **Approach** | `logs` = export existing data · `api` = expose existing public API · `redesign` = needs new headless/export path |
| **Priority** | P0 = ship first · P1 · P2 |

### Network tab

| Feature | AI type | Approach | Enable/disable (target) | Log output (target) | Priority |
|---|---|---|---|---|---|
| HTTP Inspector | data | logs | `POST /features/network` | `network.jsonl` — method, url, status, headers, body refs | P0 |
| WebSocket Inspector | data | logs | `POST /features/webSocket` | `websocket.jsonl` — connection id, frame type, payload | P0 |
| WKWebView Inspector | data | api | `POST /features/wkWebView` | merged into `network.jsonl` with `source: webview` | P1 |
| Request threshold / rate limit | data | logs | `POST /features/network.threshold` | `network-threshold.jsonl` | P1 |
| Network injection (delay/fail/rewrite) | action | api | `POST /actions/network/inject` | `network-injection.jsonl` (rule applied events) | P1 |
| Encryption/decryption | data | api | `POST /features/network.decryption` | decrypted body in `network.jsonl` when enabled | P2 |
| Session History (beta) | data | logs | `POST /features/network.sessionHistory` | SwiftData export → `sessions.json` snapshot | P2 |
| Clear history | action | api | `POST /actions/network/clear` | — | P1 |

**Existing APIs:** `DebugSwift.Network.shared`, `disable: [.network]`, `clearAllNetworkData()`

**Redesign needed:** HTTP model → stable JSON schema with body size limits (truncate >64KB, offer `GET /logs/network/:id/body`).

---

### Performance tab

| Feature | AI type | Approach | Enable/disable (target) | Log output (target) | Priority |
|---|---|---|---|---|---|
| CPU / Memory / FPS charts | data | logs | always on when tab enabled | `performance.jsonl` — timestamped metrics (1 Hz) | P0 |
| Floating Performance HUD | visual | api + screenshot | `POST /features/performance.hud` | screenshot confirms overlay | P1 |
| Memory leak detector | data | logs | `POST /features/leaksDetector` | `leaks.jsonl` — class, retain cycle hint | P0 |
| Thread checker | data | logs | `POST /features/threadChecker` | `thread-violations.jsonl` | P1 |
| Memory warning simulator | action | api | `POST /actions/performance/memoryWarning` | event in `performance.jsonl` | P2 |
| Disk I/O monitoring | data | logs | `POST /features/diskIO` | `disk-io.jsonl` | P1 |
| Battery monitoring | data | logs | `POST /features/battery` | `battery.jsonl` | P2 |
| Launch time | data | logs | auto on setup | included in `GET /status` | P1 |

**Existing APIs:** `DebugSwift.Performance.ThreadChecker.enable()`, `isBatteryMonitoringEnabled`, `disable: [.leaksDetector]`

**Redesign needed:** `PerformanceToolkit` metrics stream — today UI-bound; add timer-based sampler writing to export dir.

---

### Interface tab

| Feature | AI type | Approach | Enable/disable (target) | Log output (target) | Priority |
|---|---|---|---|---|---|
| Colorized view borders | visual | api + screenshot | `POST /features/interface.colorize` | screenshot | P1 |
| Slow animations | visual | api + screenshot | `POST /features/interface.slowAnimations` | screenshot (animation state in status) | P2 |
| Touch indicators | visual | api + screenshot | `POST /features/interface.touchIndicators` | screenshot | P1 |
| Grid overlay | visual | api + screenshot | `POST /features/interface.grid` | screenshot + grid config in status JSON | P1 |
| Dark mode override | visual | api + screenshot | `POST /features/interface.darkMode` | screenshot | P2 |
| UI measurements (HyperionSwift) | hybrid | api + screenshot | `POST /features/measurement` | `measurement.jsonl` when active | P1 |
| SwiftUI render tracking (beta) | visual | logs + screenshot | `POST /features/swiftUIRender` | `swiftui-render.jsonl` | P1 |
| Documentation Recorder | hybrid | redesign | `POST /actions/docRecorder/start\|stop` | `doc-recorder/` dir with annotated PNGs | P2 |
| View Debugger (3D) | visual | redesign | `POST /actions/viewDebugger/open` | screenshot + `view-hierarchy.json` export | P2 |

**Existing APIs:** `DebugSwift.Measurement.activate/deactivate`, `DebugSwift.SwiftUIRender.shared`, `disable: [.views]`

**Redesign needed:**
- View Debugger → export flat hierarchy JSON (already partially in `ViewElement` model)
- Doc Recorder → headless capture mode without panel UI

---

### Resources tab

| Feature | AI type | Approach | Enable/disable (target) | Log output (target) | Priority |
|---|---|---|---|---|---|
| Files (sandbox) | data | api | always available | `GET /resources/files?path=/` | P1 |
| UserDefaults | data | api | always available | `GET /resources/userdefaults` | P1 |
| Keychain | data | api | always available | `GET /resources/keychain` (keys only, no secrets in logs) | P2 |
| HTTP Cookies | data | api | always available | `GET /resources/cookies` | P2 |
| Core Data | data | api | requires host config | `GET /resources/coredata/:entity` | P2 |
| SwiftData (iOS 17+) | data | api | requires host config | `GET /resources/swiftdata/:model` | P2 |
| Database Browser (SQLite/Realm) | data | api | always available | `GET /resources/database/:path` | P2 |

**Existing APIs:** `DebugSwift.Resources.shared.configureCoreData()`, `configureAppGroups()`, `configureSwiftData()`

**Redesign needed:** Read-only JSON serializers for each store (no UI table view dependency).

---

### App tab

| Feature | AI type | Approach | Enable/disable (target) | Log output (target) | Priority |
|---|---|---|---|---|---|
| Device Info | data | logs | always on | included in `GET /status` | P0 |
| Console (print/NSLog) | data | logs | `POST /features/console` | `console.jsonl` + existing cache file | P0 |
| OSLog Console | data | logs | `POST /features/oslog` | `oslog.jsonl` | P1 |
| Crash Reports | data | logs | `POST /features/crashManager` | `crashes.jsonl` + screenshot path refs | P0 |
| Simulated Location | action | api | `POST /actions/location` | `location.jsonl` | P1 |
| Loaded Libraries | data | api | on demand | `GET /resources/libraries` | P2 |
| Push Notifications | action | api | `POST /features/pushNotifications` | `push.jsonl` | P1 |
| Deep Links | action | api | `POST /actions/deeplink` | `deeplink.jsonl` | P1 |
| Custom Info / Actions | hybrid | api | host-defined | `GET /custom/info`, `POST /custom/actions/:id` | P1 |
| APNS Token | data | logs | auto | in `GET /status` | P1 |

**Existing APIs:** `DebugSwift.PushNotification.simulate()`, `DebugSwift.Console.shared`, `disable: [.console, .crashManager]`

**Existing file log:** `Library/Caches/{bundleId}-output.log` (stdout capture — usable today on simulator)

---

### Shell / UI chrome

| Feature | AI type | Approach | Enable/disable (target) | Log output (target) | Priority |
|---|---|---|---|---|---|
| Floating ball | visual | api | `POST /features/floatBall` | screenshot | P1 |
| Present debugger UI | visual | api | `POST /actions/debugger/present` | screenshot of full debugger | P1 |
| Hide debugger UI | action | api | `POST /actions/debugger/dismiss` | — | P1 |
| Tab visibility | api | api | `POST /features/tabs/:tab` | status JSON | P1 |

**Existing APIs:** `show()`, `hide()`, `DebugSwift.App.presentDebugger()`, `debugViewController()`

---

## Visual Features & Screenshots

### Three screenshot sources (use all)

| Source | Captures | Best for |
|---|---|---|
| `xcrun simctl io booted screenshot` | Full simulator screen including status bar | Grid, HUD, float ball, app UI together |
| XcodeBuild MCP `screenshot` | Same as simctl, returns path/base64 | Cursor agent integration |
| `GET /screenshot` (in-app) | `UIWindow` render | Exact app pixels; works on device |
| `GET /screenshot?label=viewDebugger` | Named exports to `debugswift-ai/screenshots/` | Before/after comparisons |

### Visual feature workflow for AI

```bash
# 1. Enable feature
curl -X POST localhost:9999/features/interface.grid \
  -H 'Content-Type: application/json' \
  -d '{"enabled": true, "opacity": 0.3, "color": "#FF0000"}'

# 2. Wait for UI settle (agent loop or MCP wait)
sleep 0.5

# 3. Capture
xcrun simctl io booted screenshot /tmp/grid-on.png
# AND/OR
curl -s 'localhost:9999/screenshot?label=grid-on' -o /tmp/grid-in-app.png

# 4. Disable
curl -X POST localhost:9999/features/interface.grid -d '{"enabled": false}'
xcrun simctl io booted screenshot /tmp/grid-off.png
```

### Visual features requiring redesign

| Feature | Why | Redesign |
|---|---|---|
| View Debugger 3D | SceneKit view not readable as text | Export `view-hierarchy.json` + 2D snapshot |
| Doc Recorder | Multi-step annotated sequence | Headless recorder → PNG sequence in export dir |
| SwiftUI render highlights | Transient overlays | Extend `SwiftUIRenderTracker` to log render rects + optional screenshot on each render burst |
| Performance HUD | Small overlay | Include HUD metrics in `performance.jsonl` so screenshot is optional |

---

## Log Formats & Export Paths

### Directory layout

```
Library/Caches/debugswift-ai/
├── status.json              # latest snapshot (overwritten)
├── network.jsonl
├── websocket.jsonl
├── console.jsonl
├── oslog.jsonl
├── performance.jsonl
├── leaks.jsonl
├── thread-violations.jsonl
├── crashes.jsonl
├── push.jsonl
├── deeplink.jsonl
└── screenshots/
    ├── grid-on-20250616120000.png
    └── view-debugger-20250616120100.png
```

### NDJSON line schema (common envelope)

```json
{
  "ts": "2025-06-16T12:00:00.000Z",
  "feature": "network",
  "event": "request.completed",
  "data": {
    "id": "req-abc123",
    "method": "GET",
    "url": "https://api.example.com/users",
    "status": 200,
    "durationMs": 142
  }
}
```

### HTTP API (target)

| Method | Path | Description |
|---|---|---|
| `GET` | `/status` | All feature states + device info |
| `GET` | `/features` | List all controllable features |
| `POST` | `/features/:id` | `{"enabled": true, ...options}` |
| `GET` | `/logs/:stream` | Query params: `tail`, `since`, `filter` |
| `GET` | `/logs/:stream/:id` | Single record (e.g. full HTTP body) |
| `GET` | `/screenshot` | PNG bytes; query: `label` |
| `POST` | `/actions/:id` | Trigger actions (push, deeplink, memory warning) |
| `GET` | `/resources/*` | Resources tab data |

---

## Implementation Phases

> **Detailed step-by-step plans:** [docs/plans/README.md](./plans/README.md) — 22 plans with file touch lists, schemas, and verification commands.

### Phase 0 — Document & prototype (this doc)

- [x] Feature inventory
- [x] Platform matrix
- [x] Implementation plans (`docs/plans/`)
- [ ] Example app: read `DEBUGSWIFT_AI` env in Scheme → [Plan 13](./plans/13-example-integration.md)

### Phase 1 — P0 data features (MVP)

- [ ] [01 Foundation](./plans/01-foundation-module.md) + [02 Bootstrap](./plans/02-activation-bootstrap.md)
- [ ] [03 NDJSON layer](./plans/03-ndjson-export-layer.md) + [04 HTTP server](./plans/04-http-server-core.md)
- [ ] [05 Feature registry](./plans/05-feature-registry.md)
- [ ] Exporters: [06 Network](./plans/06-network-export.md), [07 Console](./plans/07-console-export.md), [08 Performance](./plans/08-performance-export.md), [09 Leaks/Crashes](./plans/09-leaks-crashes-export.md)
- [ ] [10 Status](./plans/10-status-endpoint.md) + [11 Logs/Features API](./plans/11-logs-features-api.md)
- [ ] [12 Shell scripts](./plans/12-shell-scripts.md) + [13 Example integration](./plans/13-example-integration.md)
- [ ] [22 Security baseline](./plans/22-security-hardening.md)

### Phase 2 — Visual + actions

- [ ] [14 Interface toggles](./plans/14-interface-visual-features.md)
- [ ] [15 Screenshot endpoint](./plans/15-screenshot-endpoint.md)
- [ ] [16 Actions API](./plans/16-actions-api.md)

### Phase 3 — Resources + advanced

- [ ] [17 Resources endpoints](./plans/17-resources-endpoints.md)
- [ ] [18 View hierarchy export](./plans/18-view-hierarchy-export.md)
- [ ] [19 Network injection API](./plans/19-network-injection-api.md)
- [ ] [20 Device parity](./plans/20-device-parity.md)

### Phase 4 — MCP server

- [ ] [21 MCP package](./plans/21-mcp-package.md)

---

## CLI Reference (Target)

Future `debugswift` CLI (thin wrapper over simctl + curl):

```bash
# Install (future)
brew install debugswift/tap/debugswift-cli

# Launch with AI enabled
debugswift launch --simulator "iPhone 16" --bundle com.example.app --ai

# Feature control
debugswift feature network --enable
debugswift feature interface.grid --enable --opacity 0.5

# Logs
debugswift logs network --tail 20 --follow
debugswift logs console --since 5m

# Screenshot
debugswift screenshot --output /tmp/screen.png
debugswift screenshot --in-app --label debugger-open

# Device
debugswift launch --device "Matheus iPhone" --ai --port 9999
```

Until CLI exists, use `curl` + `simctl`/`devicectl` directly (see [Terminal Workflows](#terminal-workflows-today-vs-target)).

---

## MCP Integration

Planned MCP tools (Phase 4):

| Tool | Maps to |
|---|---|
| `debugswift_status` | `GET /status` |
| `debugswift_set_feature` | `POST /features/:id` |
| `debugswift_get_logs` | `GET /logs/:stream` |
| `debugswift_screenshot` | simctl + `GET /screenshot` |
| `debugswift_action` | `POST /actions/:id` |

Cursor config (future):

```json
{
  "mcpServers": {
    "debugswift": {
      "command": "npx",
      "args": ["-y", "@debugswift/mcp"],
      "env": {
        "DEBUGSWIFT_AI_PORT": "9999",
        "DEBUGSWIFT_BUNDLE_ID": "com.example.app"
      }
    }
  }
}
```

Works alongside **XcodeBuild MCP** (`screenshot`, `snapshot_ui`, `build_run_sim`) — DebugSwift MCP adds *in-app debug data*, XcodeBuild MCP adds *build/run/sim control*.

---

## Security & Constraints

| Rule | Rationale |
|---|---|
| Bridge compiles only in `#if DEBUG` | Never ship open HTTP in Release |
| Bind `127.0.0.1` by default | Simulator/Mac localhost only |
| Optional token: `DEBUGSWIFT_AI_TOKEN` | Prevent accidental exposure if port forwarded |
| Truncate large bodies in JSONL | Avoid multi-MB log lines |
| Keychain export: keys/metadata only | No secret values in logs |
| AI bridge off by default | Opt-in via env var |

---

## Related Files

| Path | Purpose |
|---|---|
| `DebugSwift/Sources/Settings/DebugSwift.swift` | Entry point |
| `DebugSwift/Sources/Settings/FeatureHandling.swift` | Feature orchestration |
| `DebugSwift/Sources/Features/App/Console/Helpers/StdoutCapture.swift` | Existing file log |
| `DebugSwift/Sources/Features/Interface/DocRecorder/ScreenshotCapturer.swift` | Reuse for AI screenshots |
| `Example/Example/ExampleApp.swift` | Integration example (target) |

---

## Quick Answers

**Can AI control DebugSwift from the simulator terminal today?**  
Partially — screenshots yes (`simctl io screenshot`), stdout log file yes, feature toggles no (needs Phase 1 bridge).

**Can AI control it when running on a physical device from Xcode?**  
Yes, with caveats — use Scheme environment variables to enable the bridge, HTTP API for control/logs, in-app screenshot export. iOS 17+ also supports `devicectl` with `DEVICECTL_CHILD_*` env vars.

**Which features only need logs vs redesign?**  
- **Logs only:** network, console, oslog, performance metrics, leaks, crashes, push/deeplink history  
- **API expose only:** most toggles (grid, colorize, HUD, measurement)  
- **Redesign:** view debugger 3D export, doc recorder headless mode, network body pagination

**Best path for Cursor agents?**  
Simulator + `DebugSwift.AI` HTTP bridge + XcodeBuild MCP for build/run/screenshot + this doc's NDJSON tail for structured data.
