# Plan 01 — Foundation Module (`DebugSwift.AI`)

**Phase:** 1 · **Priority:** P0 · **Depends on:** —

## Goal

Create the `DebugSwift.AI` public module: types, export directory resolution, and the static API surface that every later step plugs into. No HTTP server yet — just the shell.

## Why this first

All export writers, HTTP handlers, and bootstrap logic need a single home. Today there is zero `AI` code in the repo (`grep DEBUGSWIFT` returns nothing).

## Public API (target)

```swift
#if DEBUG
public enum DebugSwiftAI {
    public static func bootstrap()
    public static func setFeature(_ id: String, enabled: Bool, options: [String: Any]?) throws
    public static func status() -> AIStatus
    public static var exportDirectory: URL { get }
    public static func captureScreenshot(label: String?) -> URL?
}
#endif
```

Supporting types:

```swift
public struct AIStatus: Codable {
    public let bridgeEnabled: Bool
    public let port: Int
    public let features: [String: FeatureState]
    public let device: DeviceInfo
    public let launchTimeMs: Double?
}

public struct FeatureState: Codable {
    public let enabled: Bool
    public let options: [String: String]?
}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/DebugSwift.AI.swift` | Public enum, re-exports |
| `DebugSwift/Sources/AI/Models/AIStatus.swift` | Codable status models |
| `DebugSwift/Sources/AI/Models/AIFeatureID.swift` | Known feature string constants |
| `DebugSwift/Sources/AI/Internal/AIConfiguration.swift` | Port, token, enabled flag (reads env) |
| `DebugSwift/Sources/AI/Internal/AIExportDirectory.swift` | `Library/Caches/debugswift-ai/` |

## Files to modify

| Path | Change |
|------|--------|
| `DebugSwift/Package.swift` or Xcode target | Add `AI` source group to DebugSwift target |
| `.gitignore` | Ignore `debugswift-ai/` in Example if needed (usually inside simulator container) |

## Implementation tasks

- [ ] Create `AIExportDirectory` resolving:
  ```swift
  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("debugswift-ai", isDirectory: true)
  ```
- [ ] On first access, `createDirectory(at:withIntermediateDirectories:)` for `debugswift-ai/` and `screenshots/`
- [ ] Wrap entire module in `#if DEBUG` — Release builds must not link AI symbols
- [ ] `AIConfiguration` reads (non-fatal defaults):
  - `DEBUGSWIFT_AI` → `ProcessInfo.processInfo.environment`
  - `DEBUGSWIFT_AI_PORT` → default `9999`
  - `DEBUGSWIFT_AI_TOKEN` → optional Bearer token
- [ ] `bootstrap()` stub: log + create export dirs (full wiring in Plan 02)
- [ ] `status()` stub: return `bridgeEnabled: false`, empty features, device info from `UIDevice` + `Bundle.main`
- [ ] `setFeature` stub: `throw AIError.notBootstrapped` until Plan 05
- [ ] `captureScreenshot` stub: return `nil` until Plan 15

## Device info helper

Reuse patterns from existing App tab view models:

```swift
DeviceInfo(
    name: UIDevice.current.name,
    model: UIDevice.current.model,
    systemVersion: UIDevice.current.systemVersion,
    bundleId: Bundle.main.bundleIdentifier ?? "",
    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
)
```

## Acceptance criteria

- [ ] `import DebugSwift` + `DebugSwiftAI.exportDirectory` compiles in DEBUG Example
- [ ] Release configuration does not expose `DebugSwiftAI`
- [ ] Export directory path matches doc: `Library/Caches/debugswift-ai/`

## Verification

```bash
# After Example integration (Plan 13), in lldb or print:
po DebugSwiftAI.exportDirectory
```

## Risks

| Risk | Mitigation |
|------|------------|
| SPM vs Xcode target file drift | Update both if dual-build (Bazel/SPM/Xcode) |
| `@MainActor` on public API | Keep `bootstrap()` callable from `AppDelegate`; use `MainActor.assumeIsolated` internally where needed |

## Next

→ [02 — Activation Bootstrap](./02-activation-bootstrap.md)
