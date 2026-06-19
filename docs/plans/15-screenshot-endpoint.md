# Plan 15 — Screenshot Endpoint

**Phase:** 2 · **Priority:** P1 · **Depends on:** [01](./01-foundation-module.md), [04](./04-http-server-core.md)

## Goal

`GET /screenshot` returns PNG bytes; labeled captures saved to `debugswift-ai/screenshots/` for before/after comparisons. Works on **device** where simctl cannot.

## Reuse existing code

`DebugSwift/Sources/Features/Interface/DocRecorder/ScreenshotCapturer.swift`

- `captureScreenshot() -> UIImage?` — composites app windows below overlay level
- Already handles multi-window scenes

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/HTTP/Handlers/AIScreenshotHandler.swift` | HTTP handler |
| `DebugSwift/Sources/AI/Internal/AIScreenshotStore.swift` | Save labeled PNGs |

## Files to modify

| Path | Change |
|------|--------|
| `DebugSwift/Sources/AI/DebugSwift.AI.swift` | Implement `captureScreenshot(label:)` |

## API

```
GET /screenshot
GET /screenshot?label=grid-on
```

Response:

- `Content-Type: image/png`
- Body: raw PNG
- If `label` provided: also write `screenshots/grid-on-20250616120000.png`

## Implementation tasks

- [ ] Handler runs on main actor (UIKit)
- [ ] Reuse `ScreenshotCapturer` — consider making it `internal` shared instance
- [ ] Filename: `{label}-{yyyyMMddHHmmss}.png` or UUID if no label
- [ ] Return latest bytes even if disk write fails
- [ ] Max dimension cap optional (none for MVP)
- [ ] Wire crash exporter screenshot ref (Plan 09)
- [ ] Update `scripts/ai-screenshot.sh` `--in-app` flag

## Three screenshot sources (doc)

| Source | When to use |
|--------|-------------|
| simctl | Full simulator chrome + status bar |
| XcodeBuild MCP | Cursor integration |
| `GET /screenshot` | Device + exact window pixels |

## Acceptance criteria

- [ ] `curl -s localhost:9999/screenshot -o /tmp/x.png && file /tmp/x.png` → PNG
- [ ] Labeled file appears in export dir
- [ ] Works with grid overlay enabled (Plan 14)

## Verification

```bash
curl -s 'localhost:9999/screenshot?label=test' -o /tmp/in-app.png
CONTAINER=$(./scripts/ai-container-path.sh com.example.app)
ls "$CONTAINER/Library/Caches/debugswift-ai/screenshots/"
```

## Next

→ [16 — Actions API](./16-actions-api.md) · [09](./09-leaks-crashes-export.md) crash screenshots
