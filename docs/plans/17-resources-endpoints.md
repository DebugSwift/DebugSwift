# Plan 17 — Resources Endpoints

**Phase:** 3 · **Priority:** P1–P2 · **Depends on:** [04](./04-http-server-core.md)

## Goal

Read-only JSON for Resources tab data — no UITableView dependency.

## Endpoints

| Method | Path | Source |
|--------|------|--------|
| GET | `/resources/files?path=/` | Sandbox browser |
| GET | `/resources/userdefaults` | UserDefaults snapshot |
| GET | `/resources/cookies` | `HTTPCookieStorage` |
| GET | `/resources/keychain` | Keys/metadata only — **no secret values** |
| GET | `/resources/libraries` | Loaded libraries VM |
| GET | `/resources/coredata/:entity` | Requires `configureCoreData()` |
| GET | `/resources/swiftdata/:model` | iOS 17+ |
| GET | `/resources/database/:path` | SQLite/Realm browser |

## Files to create

| Path | Purpose |
|------|---------|
| `DebugSwift/Sources/AI/HTTP/Handlers/AIResourcesHandler.swift` | Route multiplexer |
| `DebugSwift/Sources/AI/Resources/AIFilesSerializer.swift` | Directory listing |
| `DebugSwift/Sources/AI/Resources/AIUserDefaultsSerializer.swift` | |
| `DebugSwift/Sources/AI/Resources/AICookiesSerializer.swift` | |
| `DebugSwift/Sources/AI/Resources/AIKeychainSerializer.swift` | Metadata only |

## Files to reference (existing)

| Path | Role |
|------|------|
| `DebugSwift/Sources/Settings/DebugSwift.Resources.swift` | Configuration |
| `DebugSwift/Sources/Helpers/Managers/FileManager.swift` | Sandbox paths |
| Resources tab ViewControllers | Copy query logic, not UI |

## Security rules

- Keychain: return `account`, `service`, `accessGroup` — never `kSecValueData`
- Files: jail `path` to sandbox — reject `..` segments
- Max response size 5 MB — paginate directory listings

## Implementation tasks

- [ ] P1 first: files, userdefaults
- [ ] P2: cookies, keychain metadata, coredata/swiftdata when configured in Example
- [ ] `GET /resources/files?path=Documents` → `{ "entries": [{ "name", "isDirectory", "size" }] }`
- [ ] Optional NDJSON audit log for resource reads (debug only)

## Acceptance criteria

- [ ] `curl localhost:9999/resources/userdefaults` returns JSON dict
- [ ] Path traversal `?path=../../etc` → `400`
- [ ] Keychain response contains no plaintext secrets

## Verification

```bash
curl -s 'localhost:9999/resources/files?path=/' | jq .
curl -s localhost:9999/resources/userdefaults | jq 'keys | length'
```

## Next

→ [18](./18-view-hierarchy-export.md)
