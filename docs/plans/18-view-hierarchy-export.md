# Plan 18 — View Hierarchy Export

**Phase:** 3 · **Priority:** P2 · **Depends on:** [14](./14-interface-visual-features.md), [15](./15-screenshot-endpoint.md)

## Goal

Export flat view hierarchy JSON for AI analysis — alternative to unreadable 3D View Debugger SceneKit view.

## Existing model

`DebugSwift/Sources/Features/Interface/ViewDebugger/Models/Element.swift` (`ViewElement`)

Partial tree already built for View Debugger UI.

## Deliverables

| Output | Path |
|--------|------|
| HTTP | `GET /actions/viewDebugger/export` or `GET /resources/view-hierarchy` |
| File | `debugswift-ai/view-hierarchy.json` |
| Visual | `GET /screenshot?label=view-debugger` |

## JSON schema (flat nodes)

```json
{
  "root": "node-0",
  "nodes": [
    {
      "id": "node-0",
      "class": "UIWindow",
      "frame": {"x":0,"y":0,"w":393,"h":852},
      "accessibilityLabel": null,
      "children": ["node-1"],
      "isHidden": false,
      "alpha": 1.0
    }
  ]
}
```

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/Export/ViewHierarchy/AIViewHierarchyExporter.swift` | Walk key window |
| `DebugSwift/Sources/AI/Export/ViewHierarchy/AIViewNode.swift` | Codable node |

## Files to modify

| Path | Change |
|------|--------|
| `Element.swift` | Share traversal logic with exporter (extract `ViewHierarchyWalker`) |

## Implementation tasks

- [ ] Walk from key window root — skip DebugSwift overlay windows (same filter as `ScreenshotCapturer`)
- [ ] Max depth 30, max nodes 2000 — truncate with `"truncated": true`
- [ ] `POST /actions/viewDebugger/open` — P2: present debugger OR just export (prefer export-only for AI)
- [ ] Doc Recorder headless mode — separate P2 redesign (not this plan)

## Acceptance criteria

- [ ] Export on Example home screen → valid tree with `UIView`/`UILabel` classes
- [ ] File + HTTP return same content
- [ ] 3D debugger UI not required for export

## Verification

```bash
curl -s localhost:9999/resources/view-hierarchy | jq '.nodes | length'
```

## Next

→ [19](./19-network-injection-api.md)
