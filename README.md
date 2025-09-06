# DebugSwift

<p align="center">
<img src="https://img.shields.io/badge/Platforms-iOS%2014.0+-blue.svg"/>
<img src="https://img.shields.io/github/v/release/DebugSwift/DebugSwift?style=flat&label=Swift%20Package%20Index&color=red"/>    
<img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FDebugSwift%2FDebugSwift%2Fbadge%3Ftype%3Dswift-versions"/>
<img src="https://img.shields.io/github/license/DebugSwift/DebugSwift?style=flat"/>
</p>

| <img width="300" src="https://github.com/DebugSwift/DebugSwift/assets/31082311/3d219290-ba08-441a-a4c7-060f946683c2"> | <div align="left" >DebugSwift is a comprehensive toolkit designed to streamline and elevate the debugging experience for Swift-based applications. Whether you are troubleshooting issues or optimizing performance, DebugSwift offers a powerful set of features to make your debugging process more efficient and effective. |
|---|---|

<img width="1970" alt="Image" src="https://github.com/user-attachments/assets/a569b038-9058-4260-ae7c-47f3376cf629" />
<img width="1970" alt="Image" src="https://github.com/user-attachments/assets/334ccefa-5951-494f-8faa-5f016d39f946" />
<img width="1970" alt="Image" src="https://github.com/user-attachments/assets/246cde3c-7a14-45de-ae01-e810c42d8e65" />
<img width="1970" alt="Image" src="https://github.com/user-attachments/assets/fadde188-dcba-46d8-9460-762f9be98bd6" />
<img width="1970" height="1184" alt="Image" src="https://github.com/user-attachments/assets/8085e55c-a7e6-4e3b-8ceb-8fc7034480fe" />
<img width="1970" alt="Image" src="https://github.com/user-attachments/assets/a435a660-a4b2-4a3f-852e-a7bf0709e75e" />
<img width="1970" alt="Image" src="https://github.com/user-attachments/assets/15f34de1-214f-4bc3-95bc-b25efc2d383e" />

## 📋 Table of Contents

- [🚀 Features](#features)
- [🛠 Installation & Setup](#installation--setup)
- [📝 Examples](#examples)
- [🔧 Configuration](#configuration)

## Requirements

- **iOS 14.0+**
- **Swift 6.0+**
- **Xcode 16.0+**

## Features

### 🌐 Network Inspector
- **HTTP Monitoring:** Capture all requests/responses with detailed logs and filtering
- **WebSocket Inspector:** Zero-config automatic monitoring of WebSocket connections and frames
- **Request Limiting:** Set thresholds to monitor and control API usage
- **Smart Content:** Automatic JSON formatting with syntax highlighting
- **Encryption Support:** Automatic decryption of encrypted API responses with AES-256/128 and custom decryptors

### ⚡ Performance
- **Real-time Metrics:** Monitor CPU, memory, and FPS in real-time
- **Memory Leak Detection:** Automatic detection of leaked ViewControllers and Views
- **Thread Checker:** Detect main thread violations with detailed stack traces
- **Performance Widget:** Overlay displaying live performance stats

### 📱 App Tools
- **Crash Reports:** Detailed crash analysis with screenshots and stack traces
- **Console Logs:** Real-time console output monitoring and filtering
- **Device Info:** App version, build, device details, and more
- **APNS Tokens:** Easy access and copying of push notification tokens
- **Custom Actions:** Add your own debugging actions and info

### 🎨 Interface Tools
- **Grid Overlay:** Visual alignment grid with customizable colors and opacity
- **View Hierarchy:** 3D interactive view hierarchy inspector
- **Touch Indicators:** Visual feedback for touch interactions
- **Animation Control:** Slow down animations for easier debugging
- **View Borders:** Highlight view boundaries with colorization
- **SwiftUI Render Tracking (Beta):** Automatically detect and visualize SwiftUI view re-renders with dedicated settings screen

### 📁 Resources
- **File Browser:** Navigate app sandbox and shared app group containers
- **UserDefaults:** View and modify app preferences at runtime
- **Keychain:** Inspect keychain entries
- **Database Browser:** SQLite and Realm database inspection
- **Push Notifications:** Simulate push notifications with templates and test scenarios

## Installation & Setup

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/DebugSwift/DebugSwift.git", from: "2.0.0")
]
```

### Basic Setup

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
        // debugSwift.setup(disable: [.leaksDetector])
        debugSwift.show()
        #endif
        
        return true
    }
}
```

### Shake to Toggle (Optional)

```swift
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        #if DEBUG
        if motion == .motionShake {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.debugSwift.toggle()
            }
        }
        #endif
    }
}
```

## Examples

### Enhanced Hierarchy Tree for Deeper Application Insights (Beta)
Harness the Power of Visual Information within the iOS Hierarchy Tree to Uncover Intricate Layouts and Element Relationships in Your Application.

#### How to Use
Simply press and hold the circle button to reveal the Snapshot and Hierarchy for a comprehensive overview.

#### Results:
![image8](https://github.com/DebugSwift/DebugSwift/assets/31082311/fdc117a2-e9f9-4246-9e9e-fcae818b7ea1)

#### Explore Additional Details

Enhance your understanding by pressing and holding on a specific view to reveal information such as:
- Class
- Subviews
- Background Color
- Specific attributes based on the type (e.g., UILabel: Text, Font, and TextColor).

#### Results:
![image10](https://github.com/DebugSwift/DebugSwift/assets/31082311/7e9c3a8b-3d26-4b7c-b671-1894cb32e562)

### App Custom ViewControllers in Tab Bar

```swift
DebugSwift.App.shared.customControllers = {
    let controller1 = UITableViewController()
    controller1.title = "Custom TableVC 1"

    let controller2 = UITableViewController()
    controller2.title = "Custom TableVC 2"
    return [controller1, controller2]
}
```

### Custom Debug Actions

```swift
// Add custom debugging actions
DebugSwift.App.shared.customAction = {
    [
        .init(title: "Development Tools", actions: [
            .init(title: "Clear User Data") {
                UserDefaults.standard.removeObject(forKey: "userData")
            },
            .init(title: "Reset App State") {
                // Your reset logic here
            }
        ])
    ]
}
```

#### Results:
![image6](https://github.com/DebugSwift/DebugSwift/assets/31082311/f9c23835-e17e-49a8-b971-4b9880403b15)

### App Custom Data

```swift
DebugSwift.App.shared.customInfo = {
    [
        .init(
            title: "Info 1",
            infos: [
                .init(title: "title 1", subtitle: "title 2")
            ]
        )
    ]
}
```

#### Results:
![image5](https://github.com/DebugSwift/DebugSwift/assets/31082311/2a38e758-1418-4f14-805f-432d124ad071)

### APNS Token Integration

```swift
// In your AppDelegate
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    DebugSwift.APNSToken.didRegister(deviceToken: deviceToken)
    // Your existing token handling code
}

func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    DebugSwift.APNSToken.didFailToRegister(error: error)
    // Your existing error handling code
}
```

## Configuration

### Network Filtering

```swift
// Ignore specific URLs
DebugSwift.Network.shared.ignoredURLs = ["https://analytics.com"]

// Monitor only specific URLs
DebugSwift.Network.shared.onlyURLs = ["https://api.myapp.com"]
```

### Network Encryption/Decryption

DebugSwift supports automatic decryption of encrypted API responses, making it easier to debug apps with end-to-end encryption.

```swift
// Enable decryption feature
DebugSwift.Network.shared.setDecryptionEnabled(true)

// Register decryption key for specific API endpoints
if let key = "your-32-byte-aes-key-here-123456".data(using: .utf8) {
    DebugSwift.Network.shared.registerDecryptionKey(for: "api.example.com", key: key)
}

// Register custom decryptor for complex encryption schemes
DebugSwift.Network.shared.registerCustomDecryptor(for: "api.myapp.com") { encryptedData in
    // Your custom decryption logic here
    return customDecrypt(encryptedData)
}
```

**Features:**
- 🔍 Automatic encryption detection using entropy analysis
- 🔑 AES-256/128 decryption support with CryptoKit
- 🛠 Custom decryptor registration for proprietary encryption
- 📊 Shows both raw encrypted and decrypted responses
- 🔒 Toggle encryption/decryption with lock/unlock button in Network inspector

📖 **For more advanced examples and real-world implementations, see:** [`EncryptionExample.swift`](Example/Example/WebView/EncryptionExample.swift)

### Selective Features

```swift
debugSwift.setup(
    hideFeatures: [.performance, .interface], // Hide specific tabs
    disable: [.leaksDetector, .console]       // Disable specific monitoring
)
```

### Beta Features

```swift
// Enable beta features (disabled by default)
debugSwift.setup(
    enableBetaFeatures: [.swiftUIRenderTracking] // Enable experimental SwiftUI render tracking
)
```

### App Group Configuration

```swift
// Configure app groups for file browser access
DebugSwift.Resources.shared.configureAppGroups([
    "group.com.yourcompany.yourapp"
])
```

### Performance Monitoring

```swift
// Configure memory leak detection
DebugSwift.Performance.shared.onLeakDetected { leakData in
    print("🔴 Memory leak detected: \(leakData.message)")
}
```

### Push Notification Simulation

```swift
// Enable push notification simulation
DebugSwift.PushNotification.enableSimulation()

// Simulate a notification
DebugSwift.PushNotification.simulate(
    title: "Test Notification",
    body: "This is a test notification"
)
```

### SwiftUI Render Tracking (Beta)

⚠️ **Beta Feature**: SwiftUI render tracking is experimental and must be enabled explicitly.

```swift
// First enable the beta feature in setup
debugSwift.setup(enableBetaFeatures: [.swiftUIRenderTracking])

// Then enable SwiftUI render tracking
DebugSwift.SwiftUIRender.shared.isEnabled = true

// Configure persistent overlays (stay visible until manually cleared)
DebugSwift.SwiftUIRender.shared.persistentOverlays = true

// Set overlay style (border, borderWithCount, none)
DebugSwift.SwiftUIRender.shared.overlayStyle = .borderWithCount

// Configure overlay duration
DebugSwift.SwiftUIRender.shared.overlayDuration = 1.0

// Enable console logging
DebugSwift.SwiftUIRender.shared.loggingEnabled = true

// Clear render statistics
DebugSwift.SwiftUIRender.shared.clearStats()

// Clear persistent overlays
DebugSwift.SwiftUIRender.shared.clearPersistentOverlays()
```

---

## ⭐ Support the Project

If you find DebugSwift helpful, please consider giving us a star on GitHub! Your support helps us continue improving and adding new features.

[![GitHub stars](https://img.shields.io/github/stars/DebugSwift/DebugSwift.svg?style=social&label=Star)](https://github.com/DebugSwift/DebugSwift)

## Contributors

Our contributors have made this project possible. Thank you!

<a href="https://github.com/DebugSwift/DebugSwift/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=DebugSwift/DebugSwift" />
</a>

## Contributing

Contributions are welcome! If you have suggestions, improvements, or bug fixes, please submit a pull request. Let's make DebugSwift even more powerful together!

## Repo Activity

![Alt](https://repobeats.axiom.co/api/embed/53a4d8a27ad851f52451b14b9a1671e7124f88e8.svg "Repobeats analytics image")

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=DebugSwift/DebugSwift&type=Date)](https://star-history.com/#DebugSwift/DebugSwift&Date)

## License

DebugSwift is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [InAppViewDebugger](https://github.com/indragiek/InAppViewDebugger) 
- [CocoaDebug](https://github.com/CocoaDebug/CocoaDebug) 
- [DBDebugToolkit](https://github.com/dbukowski/DBDebugToolkit)
- [LeakedViewControllerDetector](https://github.com/Janneman84/LeakedViewControllerDetector)