<h1 align="center">DebugSwift</h1>

<p align="center">
  <strong>All-in-one in-app debugging for Swift &amp; iOS</strong><br>
  Network, performance, UI inspection, crashes, and sandbox resources — inside your running app.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platforms-iOS%2014.0+-blue.svg"/>
  <img src="https://img.shields.io/github/v/release/DebugSwift/DebugSwift?style=flat&label=Swift%20Package%20Index&color=red"/>
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FDebugSwift%2FDebugSwift%2Fbadge%3Ftype%3Dswift-versions"/>
  <img src="https://img.shields.io/github/license/DebugSwift/DebugSwift?style=flat"/>
</p>

<p align="center">
  <a href="https://debugswift.dev/docs">Documentation</a> ·
  <a href="https://debugswift.dev/install">Install guide</a> ·
  <a href="https://github.com/DebugSwift/web">Website repo</a>
</p>

<p align="center">
  <a href="https://trendshift.io/repositories/12656" target="_blank"><img src="https://trendshift.io/api/badge/repositories/12656" alt="DebugSwift on Trendshift" width="250" height="55"/></a>
</p>

| | |
|---|---|
| <img width="280" src="https://github.com/DebugSwift/DebugSwift/assets/31082311/3d219290-ba08-441a-a4c7-060f946683c2" alt="DebugSwift logo" /> | DebugSwift is an open-source debugging toolkit for iOS apps. Inspect URLSession traffic, monitor CPU and memory, browse UserDefaults and databases, and debug UI — from a floating overlay in your DEBUG build. No proxy, no certificate install, no second machine. |

### Network

| HTTP monitoring | JSON body detail | WebSocket inspector |
|:---:|:---:|:---:|
| <img src="https://debugswift.github.io/web/app-screenshots/docs/network-inspector.png" width="240" alt="Network inspector" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/http-monitoring-json-body-detail.png" width="240" alt="HTTP JSON body detail" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/websocket-inspector-connection-list.png" width="240" alt="WebSocket connection list" /> |

| Encrypted response decrypt | Response modifier |
|:---:|:---:|
| <img src="https://debugswift.github.io/web/app-screenshots/docs/encrypted-response-decrypted-json-view.png" width="240" alt="Decrypted API response" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/response-modifier-rules-list.png" width="240" alt="Response modifier rules" /> |

### Performance & App Tools

| Real-time metrics | Memory leaks | Crash reports |
|:---:|:---:|:---:|
| <img src="https://debugswift.github.io/web/app-screenshots/docs/performance.png" width="240" alt="Performance metrics" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/memory-leak-detection-leaked-objects-list.png" width="240" alt="Memory leak detection" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/crash-reports-list.png" width="240" alt="Crash reports" /> |

### Interface & Resources

| Interface tools | 3D view hierarchy | Grid overlay |
|:---:|:---:|:---:|
| <img src="https://debugswift.github.io/web/app-screenshots/docs/interface-tools.png" width="240" alt="Interface tools" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/3d-view-hierarchy-inspector.png" width="240" alt="3D view hierarchy" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/grid-overlay.png" width="240" alt="Grid overlay" /> |

| Resources browser | SwiftData browser | Documentation recorder |
|:---:|:---:|:---:|
| <img src="https://debugswift.github.io/web/app-screenshots/docs/resources.png" width="240" alt="Resources browser" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/swiftdata-model-browser.png" width="240" alt="SwiftData browser" /> | <img src="https://debugswift.github.io/web/app-screenshots/docs/documentation-recorder.png" width="240" alt="Documentation recorder" /> |

## Requirements

- **iOS 14.0+**
- **Swift 6.0+**
- **Xcode 16.0+**
- **DEBUG builds only**

## Features

### Network Inspector
- HTTP monitoring with filtering, JSON highlighting, and session history
- WebSocket inspector with zero-config frame capture
- AES-256/128 encrypted response decryption
- Response modifier with CSV import/export
- Request thresholds and session history

### Performance
- Real-time CPU, memory, and FPS metrics
- Memory leak detection for view controllers and views
- Main-thread violation checker
- Performance overlay widget

### App Tools
- Crash reports with screenshots and stack traces
- Console log monitoring
- Device and build info
- APNS token access
- Custom debug actions

### Interface Tools
- Grid overlay and view borders
- 3D view hierarchy inspector
- Touch indicators and animation slow-mo
- SwiftUI render tracking (beta)
- Documentation recorder with annotated screenshots

### Resources
- Sandbox and app group file browser
- UserDefaults and Keychain inspectors
- SQLite and Realm database browser
- Push notification simulator
- SwiftData browser (iOS 17+)

## Installation & Setup

### Swift Package Manager (recommended)

```swift
dependencies: [
    .package(url: "https://github.com/DebugSwift/DebugSwift.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → `https://github.com/DebugSwift/DebugSwift`

### CocoaPods

```ruby
# Source distribution
pod 'DebugSwift'

# XCFramework (faster CI builds)
pod 'DebugSwift', :http => 'https://github.com/DebugSwift/DebugSwift/releases/latest/download/DebugSwift.xcframework.zip'
```

### Apple Silicon

DebugSwift ships native **arm64 simulator** slices. Remove any `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` workarounds from your Podfile — they are no longer needed.

### Basic setup

```swift
import DebugSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let debugSwift = DebugSwift()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        #if DEBUG
        debugSwift.setup()
        debugSwift.show()
        #endif
        return true
    }
}
```

### Shake to toggle (optional)

```swift
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        #if DEBUG
        if motion == .motionShake {
            (UIApplication.shared.delegate as? AppDelegate)?.debugSwift.toggle()
        }
        #endif
    }
}
```

### Present programmatically

```swift
#if DEBUG
DebugSwift().setup()
let debugVC = DebugSwift.debugViewController()
navigationController?.pushViewController(debugVC, animated: true)
#endif
```

Full SwiftUI integration, network encryption, SwiftData browser, and beta features are documented at **[debugswift.dev/docs](https://debugswift.dev/docs)**.

## Examples

### Custom debug actions

```swift
DebugSwift.App.shared.customAction = {
    [
        .init(title: "Development Tools", actions: [
            .init(title: "Clear User Data") {
                UserDefaults.standard.removeObject(forKey: "userData")
            }
        ])
    ]
}
```

<p align="center">
  <img src="https://debugswift.github.io/web/app-screenshots/docs/custom-actions-menu.png" alt="Custom actions menu" width="280" />
</p>

### Network filtering

```swift
DebugSwift.Network.shared.ignoredURLs = ["https://analytics.com"]
DebugSwift.Network.shared.onlyURLs = ["https://api.myapp.com"]
```

### Selective features

```swift
debugSwift.setup(
    hideFeatures: [.performance, .interface],
    disable: [.leaksDetector, .console]
)
```

## Troubleshooting

**Apple Silicon build errors** — update to the latest release or use the XCFramework pod. Remove simulator `arm64` exclusions, then clean derived data (`⌘⇧K`).

**Network capture missing** — call `DebugSwift.setup()` before creating `URLSession` instances, or inject manually:

```swift
let config = DebugSwift.Network.shared.defaultConfiguration()
let session = URLSession(configuration: config)
```

More troubleshooting: **[debugswift.dev/docs/troubleshooting/common-issues](https://debugswift.dev/docs/troubleshooting/common-issues)**

## Support the project

[![GitHub stars](https://img.shields.io/github/stars/DebugSwift/DebugSwift.svg?style=social&label=Star)](https://github.com/DebugSwift/DebugSwift)

<a href="https://starmapper.bruniaux.com/debugswift/debugswift">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://starmapper.bruniaux.com/api/map-image/debugswift/debugswift?theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://starmapper.bruniaux.com/api/map-image/debugswift/debugswift?theme=light" />
    <img alt="StarMapper" src="https://starmapper.bruniaux.com/api/map-image/debugswift/debugswift" />
  </picture>
</a>

## Contributors

<a href="https://github.com/DebugSwift/DebugSwift/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=DebugSwift/DebugSwift" alt="Contributors" />
</a>

Contributions are welcome. Open a PR or issue on GitHub.

## Repo activity

![Repobeats](https://repobeats.axiom.co/api/embed/53a4d8a27ad851f52451b14b9a1671e7124f88e8.svg)

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=DebugSwift/DebugSwift&type=Date)](https://star-history.com/#DebugSwift/DebugSwift&Date)

## License

MIT — see [LICENSE](LICENSE).

## References

- [InAppViewDebugger](https://github.com/indragiek/InAppViewDebugger)
- [CocoaDebug](https://github.com/CocoaDebug/CocoaDebug)
- [DBDebugToolkit](https://github.com/dbukowski/DBDebugToolkit)
- [LeakedViewControllerDetector](https://github.com/Janneman84/LeakedViewControllerDetector)
