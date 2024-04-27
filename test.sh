json=$(cat <<-END
 {
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
  "body": "Full changelog: [0.3.0...0.3.1](https://github.com/DebugSwift/DebugSwift/compare/0.3.0...0.3.1)\r\n\r\nWhat\'s New:\r\n\r\nThe Podspec version was updated twice (commit 5d63f38 and 3bdcc77).\r\nLight appearance was added and improvements were made to the response date and cache policy (commit 5d63f38).\r\nThe build configuration was updated (commit f6dd030).\r\nThe example was improved, light mode was fixed, and documentation was improved (commit d12b4ef).\r\nThe README.md file was updated twice (commit 88e4690 and 3910393).\r\nA bug related to Git Actions build was fixed (commit 54ec335).\r\nCode improvements were made for theme appearance (commit 5c5c381).\r\nThe Xcode version was updated in the tag manager (commit 0f35de8).\r\nA feature was added to allow toggling the debugger (commit f9869b1).\r\nA bug related to the Xcode version in the tag generator was fixed (commit da3dceb).\r\nAutomatic scrolling was fixed (commit 0cf83ff).\r\nA feature was added to enable/disable impact feedback (commit a9dfa23).",
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
}
END
)
tag_name=$(echo "$json" | grep -o '"tag_name": *"[^"]*"' | awk -F'"' '{print $4}')
echo "$tag_name"

# echo "$json"
# tag=$(echo $json | jq -r '.tag_name')
# echo "BATATA"
# echo "::set-output name=latestTag::$tag"