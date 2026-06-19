# Plan 21 — MCP Package (`@debugswift/mcp`)

**Phase:** 4 · **Priority:** P1 · **Depends on:** [11](./11-logs-features-api.md), [15](./15-screenshot-endpoint.md), [16](./16-actions-api.md)

## Goal

Cursor MCP server that wraps the in-app HTTP bridge + simctl helpers — agents call tools instead of raw curl.

## Package layout (new repo or monorepo `packages/debugswift-mcp`)

```
packages/debugswift-mcp/
├── package.json
├── src/
│   ├── index.ts          # MCP server entry
│   ├── client.ts         # HTTP client to bridge
│   ├── simctl.ts         # screenshot, container path
│   └── tools/
│       ├── status.ts
│       ├── setFeature.ts
│       ├── getLogs.ts
│       ├── screenshot.ts
│       └── action.ts
└── README.md
```

## MCP tools (from AI_AUTOMATION.md)

| Tool | HTTP / shell |
|------|----------------|
| `debugswift_status` | `GET /status` |
| `debugswift_set_feature` | `POST /features/:id` |
| `debugswift_get_logs` | `GET /logs/:stream?tail&since` |
| `debugswift_screenshot` | simctl + optional `GET /screenshot` |
| `debugswift_action` | `POST /actions/:id` |

## Environment variables

```json
{
  "DEBUGSWIFT_AI_PORT": "9999",
  "DEBUGSWIFT_BUNDLE_ID": "com.example.app",
  "DEBUGSWIFT_AI_TOKEN": "",
  "DEBUGSWIFT_SIMULATOR_UDID": "booted"
}
```

## Cursor config snippet

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

## Coexistence with XcodeBuild MCP

| Concern | Owner |
|---------|-------|
| build, run, test | XcodeBuild MCP |
| in-app debug data, feature toggles | DebugSwift MCP |
| simulator screenshot | Either — DebugSwift adds in-app option |

Document in README: start app with XcodeBuild, then use DebugSwift tools.

## Implementation tasks

- [ ] TypeScript MCP SDK (`@modelcontextprotocol/sdk`)
- [ ] HTTP client with token header + timeout 5s
- [ ] `debugswift_get_logs` returns parsed JSON array as tool result text
- [ ] `debugswift_screenshot` params: `{ inApp?: boolean, label?: string, outputPath?: string }`
- [ ] `debugswift_set_feature` params: `{ id, enabled, options? }`
- [ ] Publish to npm `@debugswift/mcp` (or GitHub packages)
- [ ] Integration test against running Example bridge (optional CI with simulator)

## Tool schemas (sketch)

```typescript
// debugswift_set_feature
{
  id: string,
  enabled: boolean,
  options?: Record<string, unknown>
}

// debugswift_get_logs
{
  stream: 'network' | 'console' | 'performance' | ...,
  tail?: number,
  since?: string
}
```

## Acceptance criteria

- [ ] Cursor lists 5 tools when configured
- [ ] Agent can enable network + read logs in one session
- [ ] Works with `DEBUGSWIFT_AI_TOKEN` when set

## Verification

Manual in Cursor: "Enable network logging and show last 5 requests"

## Next

→ [22](./22-security-hardening.md)
