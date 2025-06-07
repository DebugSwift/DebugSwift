# DebugSwift

<p align="center">
<img src="https://img.shields.io/badge/Platforms-iOS%2014.0+-blue.svg"/>
<img src="https://img.shields.io/github/v/release/DebugSwift/DebugSwift?style=flat&label=CocoaPods"/>
<img src="https://img.shields.io/github/v/release/DebugSwift/DebugSwift?style=flat&label=Swift%20Package%20Index&color=red"/>    
<img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FDebugSwift%2FDebugSwift%2Fbadge%3Ftype%3Dswift-versions"/>
<img src="https://img.shields.io/github/license/DebugSwift/DebugSwift?style=flat"/>
</p>

| <img width="300" src="https://github.com/DebugSwift/DebugSwift/assets/31082311/3d219290-ba08-441a-a4c7-060f946683c2"> | <div align="left" >DebugSwift is a comprehensive toolkit designed to simplify and enhance the debugging process for Swift-based applications. Whether you're troubleshooting network issues, monitoring WebSocket connections, optimizing performance, or testing push notifications, DebugSwift provides a powerful set of features to make your debugging experience more efficient.<br><br>**✨ New: Unified Network Inspector with WebSocket support**<br>**🚀 Swift 6 ready with strict concurrency checking**<!/div> |
|---|---|

![image1](https://github.com/DebugSwift/DebugSwift/assets/31082311/03d0e0d0-d2ab-4fc2-8d47-e7089fffc2f6)
![image2](https://github.com/DebugSwift/DebugSwift/assets/31082311/994e75c9-948e-486b-9522-4e2a9779de4e)
![image3](https://github.com/DebugSwift/DebugSwift/assets/31082311/0aebb4ce-3e0c-4eea-b2a4-4516d916228e)
![image4](https://github.com/DebugSwift/DebugSwift/assets/31082311/fecff545-405b-493f-99f8-3ed65d453227)
![image5](https://github.com/DebugSwift/DebugSwift/assets/31082311/7e558c50-6634-4e26-9788-b1b355f121f4)
![image6](https://github.com/DebugSwift/DebugSwift/assets/31082311/d0512b4e-afbd-427f-b8e0-f125afb92416)
![image11](https://github.com/DebugSwift/DebugSwift/assets/31082311/d5f36843-1f74-49b9-89ef-1875f5ae395b)

## 📋 Table of Contents

- [🚀 Features](#features)
- [🛠 Installation](#getting-started)
- [📱 Quick Start](#usage)
- [🌐 Network Inspector](#network-configuration)
- [⚡ WebSocket Inspector](#websocket-configuration)
- [🔧 Customization](#customization)
- [📝 Examples](#quick-examples)
- [📚 Documentation](#documentation)

## 📚 Documentation

- **[Versioning Strategy](VERSIONING.md)** - Complete guide to our versioning, tagging, and release process

## Requirements

- **iOS 14.0+**
- **Swift 6.0+**
- **Xcode 16.0+**

## 🆕 What's New

### Version 2.0+ - Major Updates

- **🌐 Unified Network Inspector:** Combined HTTP and WebSocket monitoring in a single, powerful interface
- **⚡ WebSocket Inspector:** Real-time WebSocket connection and frame monitoring with smart JSON detection
- **📊 Enhanced Floating Button:** Now tracks both HTTP requests and WebSocket connections with custom animations
- **🚀 Swift 6 Compatibility:** Full support for Swift 6 with strict concurrency checking
- **🔧 Improved API:** More intuitive configuration with `.shared` pattern across all singletons
- **📱 Better UI/UX:** Refined interface with better visual indicators and smoother animations
- **⚠️ Memory Leak Detection:** Enhanced leak detection with better reporting and analytics
- **🎯 Smart Content Detection:** Automatic JSON formatting and syntax highlighting in network inspector

## Features

### App Settings

- **Crash Reports:** Access detailed crash reports for analysis and debugging.
- **Change Location:** Simulate different locations for testing location-based features.
- **Console:** Monitor and interact with the application's console logs.
- **Custom Info:** Add custom information for quick access during debugging.
- **Version:** View the current application version.
- **Build:** Identify the application's build number.
- **Bundle Name:** Retrieve the application's bundle name.
- **Bundle ID:** Display the unique bundle identifier for the application.
- **Device Infos:** Access information about the device running the application.
- **APNS Device Token:** View and copy the Apple Push Notification Service device token for debugging push notifications:
  - Real-time registration status tracking (not requested, pending, registered, failed, denied)
  - One-tap token copying to clipboard for manual testing
  - APNS environment detection (development/production)
  - Error details for failed registrations
  - Refresh mechanism to update token status
  - Direct integration with notification settings
- **Loaded Libraries:** Explore all loaded libraries (frameworks, dylibs) with detailed information:
  - View public and private libraries with their file paths and memory addresses
  - Filter libraries by type (Public/Private) or search by name
  - Expand libraries to see all their Objective-C classes
  - Explore class details including properties, methods, and protocols
  - Create class instances to inspect their default state
  - Export comprehensive reports of all loaded libraries

| Libraries List | Class Explorer | Class Details |
|:--------------:|:--------------:|:-------------:|
| ![Simulator Screenshot - iPhone 16 Pro - 2025-06-03 at 14 44 29](https://github.com/user-attachments/assets/dc17b475-d184-483d-9535-2d12bd54b42c) | ![Simulator Screenshot - iPhone 16 Pro - 2025-06-03 at 14 44 37](https://github.com/user-attachments/assets/fc654df0-d1aa-4e42-b708-ffa389cccd5c) | ![Simulator Screenshot - iPhone 16 Pro - 2025-06-03 at 14 44 42](https://github.com/user-attachments/assets/af1634de-d9a4-4d77-9b6f-58c65c2753ab) |

### Interface

- **Grid:** Overlay a grid on the interface to assist with layout alignment.
- **Slow Animations:** Slow down animations for better visualization and debugging.
- **Showing Touches:** Highlight touch events for easier interaction tracking.
- **Colorized View with Borders:** Apply colorization and borders to views for improved visibility.

### Network Inspector

Comprehensive network traffic monitoring with unified HTTP and WebSocket inspection:

#### HTTP Monitoring
- **All Response/Request Logs:** Capture and review detailed logs of all network requests and responses
- **Request/Response Details:** Full headers, body content, timing information, and status codes
- **Search & Filter:** Find specific requests with powerful search and filtering capabilities
- **Copy & Share:** Copy URLs, export request data, and share network logs
- **Threshold Request Limiter:** Monitor and control network request rates with customizable thresholds:
  - Set global or endpoint-specific request limits
  - Configure time windows for rate limiting
  - Receive alerts when thresholds are exceeded
  - Optional request blocking when limits are reached
  - Detailed breach history and analytics

#### WebSocket Inspector (New!)
- **Real-time Connection Monitoring:** Track WebSocket connections with live status updates
- **Frame Inspection:** Monitor sent and received frames with timestamp precision
- **Smart Content Detection:** Automatic JSON formatting with syntax highlighting
- **Message Types:** Support for text, binary, ping/pong, and control frames
- **Connection Management:** Close connections, clear frame history, and connection info
- **Search & Resend:** Search through frames and resend messages for testing
- **Channel Organization:** Group connections by custom channel names

| HTTP Requests | WebSocket Connections | Frame Timeline |
|:-------------:|:--------------------:|:--------------:|
| ![HTTP Inspector](https://github.com/user-attachments/assets/http-inspector) | ![WebSocket Connections](https://github.com/user-attachments/assets/websocket-connections) | ![Frame Timeline](https://github.com/user-attachments/assets/frame-timeline) |

### Performance

- **CPU, Memory, FPS, Memory Leak Detector:** Monitor and analyze CPU usage, memory consumption, and frames per second in real-time.

### Push Notifications

- **Push Notification Simulation:** Test push notifications using local notifications without requiring a server setup. Features include:
  - **Template System:** Pre-built notification templates for common scenarios (messages, news, marketing, system alerts)
  - **Custom Notifications:** Create detailed notifications with title, body, subtitle, badge, sound, and custom user info
  - **Scheduled Delivery:** Support for immediate, delayed, and date-based notification triggers
  - **Interaction Simulation:** Simulate user taps, dismissals, and custom notification actions
  - **Foreground/Background Testing:** Test notification behavior in different app states
  - **History Tracking:** Complete history of sent notifications with status tracking
  - **Test Scenarios:** Pre-configured test flows for comprehensive notification testing
  - **Configuration Options:** Customize notification presentation, sounds, badges, and interaction behavior

### Resources

- **Keychain:** Inspect and manage data stored in the keychain.
- **User Defaults:** View and modify user defaults for testing different application states.
- **Files:** Access and analyze files stored by the application and app group containers:
  - Browse app sandbox directories with full navigation
  - Access shared app group containers with automatic detection
  - Switch between app sandbox and app groups with segmented control
  - View, delete, and export files from any accessible location
  - Smart detection of app group identifiers from entitlements
  - Professional UI with visual indicators for container types

## Getting Started

### Installation

#### Swift Package Manager (SPM)

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/DebugSwift/DebugSwift.git", from: "1.0.0")
]
```

Then, add `"DebugSwift"` to your target's dependencies.

### Usage

```swift
import DebugSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let debugSwift = DebugSwift()
    
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

### Usage to show or hide with shake.
```swift
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        #if DEBUG
        if motion == .motionShake {
            // Assuming you have a reference to your DebugSwift instance
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.debugSwift.toggle()
            }
        }
        #endif
    }
}
```

### Quick Start with App Groups (Optional)

If your app uses shared app group containers (for extensions, widgets, etc.), you can configure them for debugging:

```swift
#if DEBUG
// Configure app groups for file browser access
DebugSwift.Resources.shared.configureAppGroups([
    "group.com.yourcompany.yourapp",
    "group.com.yourcompany.widgets"
])

debugSwift.setup()
debugSwift.show()
#endif
```

**Note**: App groups are automatically detected from your app's entitlements if not manually configured.

## Quick Examples

### Complete WebSocket Chat Integration

```swift
import DebugSwift

class ChatManager {
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect() {
        let url = URL(string: "wss://chat.example.com/websocket")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        
        // Register with DebugSwift for monitoring
        DebugSwift.WebSocket.register(task: webSocketTask!, channelName: "Chat")
        
        webSocketTask?.resume()
        startListening()
    }
    
    func sendMessage(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Send failed: \(error)")
            }
        }
        
        // Log sent frame for DebugSwift monitoring
        DebugSwift.WebSocket.logSentFrame(task: webSocketTask!, text: text)
    }
    
    private func startListening() {
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                // Handle received message
                self.startListening() // Continue listening
            case .failure(let error):
                print("Receive failed: \(error)")
            }
        }
    }
}
```

### Network + Performance Monitoring Setup

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let debugSwift = DebugSwift()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        // Configure network monitoring
        DebugSwift.Network.shared.ignoredURLs = [
            "https://analytics.example.com"  // Ignore analytics endpoints
        ]
        
        // Set request threshold monitoring
        DebugSwift.Network.shared.setThreshold(100, timeWindow: 60.0)
        DebugSwift.Network.shared.setRequestBlocking(true)
        
        // Setup memory leak detection
        DebugSwift.Performance.shared.onLeakDetected { leakData in
            print("🔴 Memory leak detected: \(leakData.message)")
            // Send to analytics or logging service
        }
        
        // Enable push notification testing
        DebugSwift.PushNotification.enableSimulation()
        
        // Setup and show DebugSwift
        debugSwift.setup()
        debugSwift.show()
        #endif
        
        return true
    }
}
```

### Custom Actions & Info Integration

```swift
// Add custom debugging actions
DebugSwift.App.shared.customAction = {
    [
        .init(title: "Development Tools", actions: [
            .init(title: "Clear User Data") {
                UserDefaults.standard.removeObject(forKey: "userData")
                print("✅ User data cleared")
            },
            .init(title: "Simulate Network Error") {
                // Trigger a test network error
                self.simulateNetworkError()
            },
            .init(title: "Test WebSocket Reconnection") {
                self.chatManager.reconnect()
            }
        ]),
        .init(title: "Feature Flags", actions: [
            .init(title: "Enable Beta Features") {
                FeatureFlags.shared.enableBetaFeatures()
            }
        ])
    ]
}

// Add custom development information
DebugSwift.App.shared.customInfo = {
    [
        .init(title: "Environment Info", infos: [
            .init(title: "API Environment", subtitle: Configuration.apiEnvironment),
            .init(title: "Feature Flags", subtitle: FeatureFlags.shared.enabledFlags.joined(separator: ", ")),
            .init(title: "Database", subtitle: CoreDataManager.shared.storeURL.lastPathComponent)
        ]),
        .init(title: "User Session", infos: [
            .init(title: "User ID", subtitle: UserSession.shared.userId ?? "Not logged in"),
            .init(title: "Session Token", subtitle: UserSession.shared.hasValidToken ? "Valid" : "Invalid")
        ])
    ]
}
```

### APNS Device Token Integration

To enable APNS device token tracking in DebugSwift, integrate the following code into your AppDelegate:

```swift
import DebugSwift
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Your existing DebugSwift setup
        #if DEBUG
        debugSwift.setup().show()
        #endif
        
        // Request push notification permissions
        requestPushNotificationPermissions()
        
        return true
    }
    
    private func requestPushNotificationPermissions() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            
            // Inform DebugSwift that we're about to request permissions
            DebugSwift.APNSToken.willRequestPermissions()
            
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    DebugSwift.APNSToken.didDenyPermissions()
                }
            } catch {
                DebugSwift.APNSToken.didFailToRegister(error: error)
            }
        }
    }
    
    // MARK: - Push Notification Delegate Methods
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Register with DebugSwift for debugging
        DebugSwift.APNSToken.didRegister(deviceToken: deviceToken)
        
        // Your existing token handling code here
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device token: \(tokenString)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Register failure with DebugSwift
        DebugSwift.APNSToken.didFailToRegister(error: error)
        
        // Your existing error handling code here
        print("❌ Failed to register: \(error.localizedDescription)")
    }
}
```

#### APNS Token Features:

- **Status Tracking**: View current registration state in Device Info section
- **Copy to Clipboard**: Tap the Push Token row to copy the token for manual testing
- **Environment Detection**: Automatically detects development vs production APNS environment
- **Error Details**: Tap on failed registrations to see detailed error information
- **Refresh Button**: Use the refresh button in the navigation bar to update token status
- **Settings Integration**: Direct links to notification settings when permissions are denied

#### Programmatic Access:

```swift
// Get current device token
let token = DebugSwift.APNSToken.deviceToken

// Check registration state
let state = DebugSwift.APNSToken.registrationState

// Get APNS environment
let environment = DebugSwift.APNSToken.environment

// Copy token to clipboard programmatically
let copied = DebugSwift.APNSToken.copyToClipboard()

// Refresh registration status
await DebugSwift.APNSToken.refreshStatus()
```

#### Why This Matters:

When debugging push notification flows, developers often need the exact device token to:
- Send test pushes from their server or testing tools
- Verify token registration with their backend
- Debug notification delivery issues
- Test different APNS environments

DebugSwift eliminates the need for manual token logging and provides a convenient interface for accessing and copying tokens during development.

## Customization

### Network Configuration

If you want to ignore specific URLs, use the following code:

```swift
DebugSwift.Network.shared.ignoredURLs = ["https://reqres.in/api/users/23"]
```

If you want to capture only a specific URL, use the following code:

```swift
DebugSwift.Network.shared.onlyURLs = ["https://reqres.in/api/users/23"]
```

Adjust the URLs in the arrays according to your needs.

### Network Threshold Configuration

Configure request rate limiting to prevent API abuse and monitor network usage:

```swift
// Basic threshold configuration
DebugSwift.Network.shared.threshold = 100  // 100 requests per minute
DebugSwift.Network.shared.enableRequestTracking()

// Advanced configuration with custom time window
DebugSwift.Network.shared.setThreshold(50, timeWindow: 30.0)  // 50 requests per 30 seconds

// Configure alert settings
DebugSwift.Network.shared.setThresholdAlert(
    emoji: "🚨", 
    message: "Too many requests!"
)

// Enable request blocking when threshold is exceeded
DebugSwift.Network.shared.setRequestBlocking(true)

// Set endpoint-specific limits
DebugSwift.Network.shared.setEndpointThreshold(
    "api/users", 
    limit: 50, 
    timeWindow: 60.0
)

// Monitor current request count
let currentCount = DebugSwift.Network.shared.getCurrentRequestCount()
print("Current requests: \(currentCount)")

// View breach history
let breaches = DebugSwift.Network.shared.getBreachHistory()
for breach in breaches {
    print("Breach at \(breach.timestamp): \(breach.message)")
}
```

All threshold configurations are automatically persisted using UserDefaults.

#### Results:
When the threshold is exceeded, you'll see:
- Visual alerts in the app with your configured emoji and message
- Color-coded status in the Network tab header (green → orange → red)
- Detailed breach history in the threshold configuration screen
- Optional blocking of requests returning 429 errors

### WebSocket Configuration

Monitor WebSocket connections in real-time with comprehensive frame inspection:

#### Basic Setup

```swift
// WebSocket monitoring is enabled automatically with DebugSwift
// Register individual connections for tracking
let task = URLSession.shared.webSocketTask(with: url)
DebugSwift.WebSocket.register(task: task, channelName: "Chat Channel")
task.resume()
```

#### Advanced Usage

```swift
// Create and register WebSocket with custom channel name
let webSocketURL = URL(string: "wss://api.example.com/websocket")!
let task = URLSession.shared.webSocketTask(with: webSocketURL)

// Register with DebugSwift for monitoring
DebugSwift.WebSocket.register(task: task, channelName: "Live Updates")

// Send messages and log them automatically
task.send(.string("Hello WebSocket!")) { error in
    if let error = error {
        print("Send failed: \(error)")
    }
}

// Log sent frames manually for complete monitoring
DebugSwift.WebSocket.logSentFrame(task: task, text: "Hello WebSocket!")

// Start the connection
task.resume()
```

#### Frame Logging

```swift
// Log different types of sent frames
DebugSwift.WebSocket.logSentFrame(task: task, text: "Text message")
DebugSwift.WebSocket.logSentFrame(task: task, data: jsonData)
DebugSwift.WebSocket.logSentFrame(task: task, message: .string("Direct message"))

// Convenience methods for common patterns
let jsonMessage = """
{
    "type": "message",
    "content": "Hello World",
    "timestamp": "\(Date().timeIntervalSince1970)"
}
"""
DebugSwift.WebSocket.logSentFrame(task: task, text: jsonMessage)
```

#### Configuration Options

```swift
// Enable/disable WebSocket monitoring
DebugSwift.WebSocket.enableMonitoring()
DebugSwift.WebSocket.disableMonitoring()

// Check monitoring status
let isEnabled = DebugSwift.WebSocket.isMonitoringEnabled

// Get connection statistics
let activeConnections = DebugSwift.WebSocket.activeConnectionCount
let totalUnreadFrames = DebugSwift.WebSocket.totalUnreadFrames

// Data management
DebugSwift.WebSocket.clearAllData()
DebugSwift.WebSocket.clearFrames(for: webSocketURL)
```

#### Results:
The WebSocket Inspector provides:
- **🟢 Connected/🟠 Connecting/🔴 Error Status:** Visual connection state indicators
- **📤📥 Frame Direction:** Clear sent/received frame identification with timestamps
- **🟢 JSON/🔵 TEXT/🟡 BIN Labels:** Smart content type detection and formatting
- **⚡ Real-time Updates:** Live frame monitoring as they're sent/received
- **🔍 Search & Filter:** Find specific frames by content, type, or direction
- **🔄 Resend Capability:** Replay frames for testing and debugging
- **📊 Connection Info:** Detailed connection metadata and statistics

Perfect for debugging:
- WebSocket connection lifecycle
- Message formatting and content
- Real-time data synchronization
- Chat and live update features
- API communication protocols

### Push Notification Simulation

Test push notifications without setting up a push notification service or server. Perfect for development and testing scenarios.

#### Basic Usage

```swift
// Enable push notification simulation
DebugSwift.PushNotification.enableSimulation()

// Simple notification
DebugSwift.PushNotification.simulate(
    title: "New Message",
    body: "You have a new message"
)

// Detailed notification with all options
DebugSwift.PushNotification.simulate(
    title: "Special Offer! 🎉",
    body: "Get 50% off your next purchase",
    subtitle: "Limited time offer",
    badge: 1,
    sound: "default",
    userInfo: ["type": "marketing", "discount": "50"],
    delay: 5.0  // Show after 5 seconds
)
```

#### Using Templates

```swift
// Use predefined templates
DebugSwift.PushNotification.simulateFromTemplate("Message")
DebugSwift.PushNotification.simulateFromTemplate("News Update", delay: 3.0)

// Quick convenience methods
DebugSwift.PushNotification.simulateMessage(from: "John", message: "Hey, how are you?")
DebugSwift.PushNotification.simulateReminder("Meeting at 3 PM", in: 60.0)
DebugSwift.PushNotification.simulateNews(headline: "Breaking: New iOS version released", category: "Technology")
DebugSwift.PushNotification.simulateMarketing(title: "Flash Sale!", offer: "50% off everything", discount: "50")
```

#### Test Scenarios

```swift
// Run comprehensive test scenarios
DebugSwift.PushNotification.runTestScenario(.messageFlow)      // 3 message-related notifications
DebugSwift.PushNotification.runTestScenario(.newsUpdates)     // News, sports, weather updates
DebugSwift.PushNotification.runTestScenario(.marketingCampaign) // Welcome, cart reminder, flash sale
DebugSwift.PushNotification.runTestScenario(.systemAlerts)    // Security, backup, update notifications

// Create custom scenarios
let customNotifications = [
    SimulatedNotification(title: "Step 1", body: "First notification"),
    SimulatedNotification(title: "Step 2", body: "Second notification"),
    SimulatedNotification(title: "Step 3", body: "Final notification")
]
DebugSwift.PushNotification.runTestScenario(.customFlow(customNotifications))
```

#### Interaction Simulation

```swift
// Simulate user interactions
DebugSwift.PushNotification.simulateInteraction(identifier: "notification-id")
DebugSwift.PushNotification.simulateForegroundNotification(identifier: "notification-id")
DebugSwift.PushNotification.simulateBackgroundNotification(identifier: "notification-id")
```

#### Template Management

```swift
// Add custom templates
let customTemplate = NotificationTemplate(
    name: "Custom Alert",
    title: "System Alert",
    body: "{{message}}",
    sound: "alarm",
    userInfo: ["type": "system"]
)
DebugSwift.PushNotification.addTemplate(customTemplate)

// Get all templates
let templates = DebugSwift.PushNotification.templates

// Remove template
DebugSwift.PushNotification.removeTemplate(id: "template-id")
```

#### Configuration

```swift
// Configure notification behavior
var config = DebugSwift.PushNotification.configuration
config.showInForeground = true      // Show notifications while app is active
config.playSound = true             // Enable notification sounds
config.showBadge = true             // Show badge numbers
config.autoInteraction = false      // Automatically interact with notifications
config.interactionDelay = 3.0       // Delay before auto-interaction
config.maxHistoryCount = 100        // Maximum notifications to keep in history

DebugSwift.PushNotification.updateConfiguration(config)
```

#### History Management

```swift
// Get notification history
let history = DebugSwift.PushNotification.history

// Clear all history
DebugSwift.PushNotification.clearHistory()

// Remove specific notification
DebugSwift.PushNotification.removeNotification(id: "notification-id")
```

#### Results:
The push notification simulator provides:
- **Real Notifications**: Actual system notifications that appear like real push notifications
- **Status Tracking**: Monitor delivery, interaction, and dismissal status
- **Template Library**: Pre-built templates for common notification types
- **Test Scenarios**: Comprehensive flows for thorough testing
- **History Management**: Complete tracking of all simulated notifications
- **Configuration Options**: Fine-tune notification behavior and presentation

Perfect for testing:
- Notification handling logic
- UI responses to notifications
- Different notification content types
- User interaction patterns
- Foreground vs background behavior

### Floating Button Indicators

The DebugSwift floating button provides real-time feedback about your app's network activity:

- **📊 Count Display:** Shows total count of HTTP requests + WebSocket connections
- **🚀 HTTP Success:** Green rocket animation for successful HTTP requests
- **❌ HTTP Error:** Red X animation for failed HTTP requests  
- **⚡ WebSocket Activity:** Lightning bolt animation for WebSocket connections
- **⚠️ Memory Leaks:** Warning animations for detected memory leaks

The floating button count combines both HTTP requests and active WebSocket connections, giving you a comprehensive view of your app's network activity at a glance.

### App Group Container Configuration

Configure shared app group containers for file system debugging across app extensions and related apps:

```swift
// Configure app group identifiers for file browser access
DebugSwift.Resources.shared.configureAppGroups([
    "group.com.yourcompany.yourapp",
    "group.com.yourcompany.shared"
])

// Add individual app groups
DebugSwift.Resources.shared.addAppGroup("group.com.yourcompany.widgets")

// Remove specific app groups
DebugSwift.Resources.shared.removeAppGroup("group.com.yourcompany.old")

// Get accessible app group containers
let accessibleGroups = DebugSwift.Resources.shared.getAccessibleAppGroups()
for (identifier, url) in accessibleGroups {
    print("App Group: \(identifier) at \(url.path)")
}
```

#### Automatic Detection:
If no app groups are configured, DebugSwift will automatically:
1. Try to read your app's entitlements plist
2. Extract app group identifiers from `com.apple.security.application-groups`
3. Auto-configure detected app groups for immediate use

#### File Browser Features:
- **Segmented Control**: Switch between "App Sandbox" and "App Groups"
- **Visual Indicators**: App group containers show clear labels
- **Full Navigation**: Browse deep into app group directory structures
- **File Operations**: View, delete, and export files from shared containers
- **Error Handling**: Clear messages when app groups are inaccessible

#### Results:
The Files browser will show a segmented control allowing you to switch between:
- **App Sandbox**: Traditional app documents, library, and tmp directories
- **App Groups**: Shared containers accessible by your app and extensions

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

---

### App Custom Action

```swift
DebugSwift.App.shared.customAction = {
    [
        .init(
            title: "Action 1",
            actions: [
                .init(title: "action 1") { [weak self] in // Important if use self
                    print("Action 1")
                }
            ]
        )
    ]
}
```

#### Results:
![image6](https://github.com/DebugSwift/DebugSwift/assets/31082311/f9c23835-e17e-49a8-b971-4b9880403b15)

---
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

---
### Hide or disable Some Features
If you prefer to selectively disable certain features, DebugSwift can now deactivate unnecessary functionalities. This can assist you in development across various environments.

#### Usage

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let debugSwift = DebugSwift()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        #if DEBUG
        debugSwift.setup(
            // Main features - WebSocket is now part of .network
            hideFeatures: [
                .network,      // Includes both HTTP and WebSocket inspectors
                .resources, 
                .performance, 
                .interface, 
                .app
            ],
            // Swizzle features - Fine-grained control over monitoring
            disable: [
                .network,           // HTTP request monitoring
                .webSocket,         // WebSocket connection monitoring  
                .location,          // Location simulation
                .views,             // UI view debugging
                .crashManager,      // Crash report collection
                .leaksDetector,     // Memory leak detection
                .console,           // Console log capture
                .pushNotifications  // Push notification simulation
            ]
        )
        debugSwift.show()
        #endif
        
        return true
    }
}
```
#### Results:
![image9](https://github.com/DebugSwift/DebugSwift/assets/31082311/a1261022-c193-40c9-999f-80129b34dda0)

---

### Collect Memory Leaks
Get the data from memory leaks in the app.

#### Usage

```swift
DebugSwift.Performance.shared.onLeakDetected { data in
    // If you want to send data to some analytics

    print(data.message) // Returns the name of the class and the error
    print(data.controller) // If is a controller leak
    print(data.view) // If is a view leak
    print(data.isDeallocation) // If is a deallocation of leak (good for false/positive)
}
```

#### Results:
![image12](https://github.com/DebugSwift/DebugSwift/assets/31082311/e9acc5c5-83d4-487d-bd7e-8a66dfbc3b21)

---

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


---

## Migration from Previous Versions

### Breaking Changes in Swift 6 Version

1. **Minimum iOS Version**: Now requires iOS 14.0+ (previously iOS 12.0+)
2. **Swift Version**: Requires Swift 6.0+ with strict concurrency checking
3. **API Changes**:
   - `DebugSwift` is now a class, not an enum
   - All singletons now use `.shared` pattern
   - Methods that access UI must be called from MainActor

### Migration Examples

```swift
// Before (old version)
DebugSwift.setup()
DebugSwift.show()
DebugSwift.App.customInfo = { ... }
DebugSwift.Network.ignoredURLs = [...]

// After (Swift 6 version)
let debugSwift = DebugSwift()
debugSwift.setup()
debugSwift.show()
DebugSwift.App.shared.customInfo = { ... }
DebugSwift.Network.shared.ignoredURLs = [...]
```
---

## Fixing Errors

### Alamofire

#### Not called `uploadProgress`

In the `AppDelegate`.

```swift
class AppDelegate {
    let debugSwift = DebugSwift()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        debugSwift.setup()
        debugSwift.show()

        // Call this method
        DebugSwift.Network.shared.delegate = self
        return true
    }
}
```

And conform with the protocol:
```swift
extension AppDelegate: CustomHTTPProtocolDelegate {
    func urlSession(
        _ protocol: URLProtocol,
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {

        Session.default.session.getAllTasks { tasks in
            let uploadTask = tasks.first(where: { $0.taskIdentifier == task.taskIdentifier }) ?? task
            Session.default.rootQueue.async {
                Session.default.delegate.urlSession(
                    session,
                    task: uploadTask,
                    didSendBodyData: bytesSent,
                    totalBytesSent: totalBytesSent,
                    totalBytesExpectedToSend: totalBytesExpectedToSend
                )
            }
        }
    }
}
```

---

## ⭐ Support the Project by Leaving a Star!

Thank you for visiting our project! If you find our work helpful and would like to support us, please consider giving us a ⭐ star on GitHub. Your support is crucial for us to continue improving and adding new features.

### Why Should You Star the Project?

- **Show Your Support**: Let us know that you appreciate our efforts.
- **Increase Visibility**: Help others discover this project.
- **Stay Updated**: Get notifications on updates and new releases.
- **Motivate Us**: Encouragement from the community keeps us going!

### How to Leave a Star

1. **Log in** to your GitHub account.
2. **Navigate** to the top of this repository page.
3. **Click** on the "Star" button located at the top-right corner.

Every star counts and makes a difference. Thank you for your support! 😊

[![GitHub stars](https://img.shields.io/github/stars/DebugSwift/DebugSwift.svg?style=social&label=Star)](https://github.com/DebugSwift/DebugSwift)

---

## Contributors

Our contributors have made this project possible. Thank you!

<a href="https://github.com/DebugSwift/DebugSwift/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=DebugSwift/DebugSwift" />
</a>

## Contributing

Contributions are welcome! If you have suggestions, improvements, or bug fixes, please submit a pull request. Let's make DebugSwift even more powerful together!

---

# Repo Activity

![Alt](https://repobeats.axiom.co/api/embed/53a4d8a27ad851f52451b14b9a1671e7124f88e8.svg "Repobeats analytics image")

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=DebugSwift/DebugSwift&type=Date)](https://star-history.com/#DebugSwift/DebugSwift&Date)

---

## License

DebugSwift is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [InAppViewDebugger](https://github.com/indragiek/InAppViewDebugger) 
- [CocoaDebug](https://github.com/CocoaDebug/CocoaDebug) 
- [DBDebugToolkit](https://github.com/dbukowski/DBDebugToolkit)
- [LeakedViewControllerDetector](https://github.com/Janneman84/LeakedViewControllerDetector)
