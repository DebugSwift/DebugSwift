json='{
  "url": "https://api.github.com/repos/DebugSwift/DebugSwift/releases/146176701",
  "assets_url": "https://api.github.com/repos/DebugSwift/DebugSwift/releases/146176701/assets",
  "upload_url": "https://uploads.github.com/repos/DebugSwift/DebugSwift/releases/146176701/assets{?name,label}",
  "html_url": "https://github.com/DebugSwift/DebugSwift/releases/tag/0.3.1",
  "id": 146176701,
  "author": {
    "login": "github-actions[bot]",
    "id": 41898282,
    "node_id": "MDM6Qm90NDE4OTgyODI=",
    "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/github-actions%5Bbot%5D",
    "html_url": "https://github.com/apps/github-actions",
    "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
    "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
    "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
    "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
    "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
    "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
    "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
    "type": "Bot",
    "site_admin": false
  },
  "node_id": "RE_kwDOK55z1M4Itnq9",
  "tag_name": "0.3.1",
  "target_commitish": "d5057a779742231bdcb766dff8647631f851348e",
  "name": "Release 0.3.1",
  "draft": false,
  "prerelease": false,
  "created_at": "2024-03-13T02:01:42Z",
  "published_at": "2024-03-13T02:02:50Z",
  "assets": [],
  "tarball_url": "https://api.github.com/repos/DebugSwift/DebugSwift/tarball/0.3.1",
  "zipball_url": "https://api.github.com/repos/DebugSwift/DebugSwift/zipball/0.3.1",
  "reactions": {
    "url": "https://api.github.com/repos/DebugSwift/DebugSwift/releases/146176701/reactions",
    "total_count": 1,
    "+1": 0,
    "-1": 0,
    "laugh": 0,
    "hooray": 1,
    "confused": 0,
    "heart": 0,
    "rocket": 0,
    "eyes": 0
  }
}'
# echo "$json"
# tag=$(echo "$json" | jq -r '.tag_name')
# echo "BATATA"
# echo "::set-output name=latestTag::$tag"