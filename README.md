# DebugSwift

<p align="center">
<img src="https://img.shields.io/badge/Platforms-iOS%2012.0+-blue.svg"/>
<img src="https://img.shields.io/github/v/release/DebugSwift/DebugSwift?style=flat&label=CocoaPods"/>
<img src="https://img.shields.io/github/v/release/DebugSwift/DebugSwift?style=flat&label=Swift%20Package%20Index&color=red"/>    
<img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FDebugSwift%2FDebugSwift%2Fbadge%3Ftype%3Dswift-versions"/>
<img src="https://img.shields.io/github/license/DebugSwift/DebugSwift?style=flat"/>
</p>

| <img width="300" src="https://github.com/DebugSwift/DebugSwift/assets/31082311/3d219290-ba08-441a-a4c7-060f946683c2"> | <div align="left" >DebugSwift is a comprehensive toolkit designed to simplify and enhance the debugging process for Swift-based applications. Whether you're troubleshooting issues or optimizing performance, DebugSwift provides a set of powerful features to make your debugging experience more efficient.</div> |
|---|---|

![image1](https://github.com/DebugSwift/DebugSwift/assets/31082311/03d0e0d0-d2ab-4fc2-8d47-e7089fffc2f6)
![image2](https://github.com/DebugSwift/DebugSwift/assets/31082311/994e75c9-948e-486b-9522-4e2a9779de4e)
![image3](https://github.com/DebugSwift/DebugSwift/assets/31082311/0aebb4ce-3e0c-4eea-b2a4-4516d916228e)
![image4](https://github.com/DebugSwift/DebugSwift/assets/31082311/fecff545-405b-493f-99f8-3ed65d453227)
![image5](https://github.com/DebugSwift/DebugSwift/assets/31082311/7e558c50-6634-4e26-9788-b1b355f121f4)
![image6](https://github.com/DebugSwift/DebugSwift/assets/31082311/d0512b4e-afbd-427f-b8e0-f125afb92416)
![image11](https://github.com/DebugSwift/DebugSwift/assets/31082311/d5f36843-1f74-49b9-89ef-1875f5ae395b)

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

### Interface

- **Grid:** Overlay a grid on the interface to assist with layout alignment.
- **Slow Animations:** Slow down animations for better visualization and debugging.
- **Showing Touches:** Highlight touch events for easier interaction tracking.
- **Colorized View with Borders:** Apply colorization and borders to views for improved visibility.

### Network Logs

- **All Response/Request Logs:** Capture and review detailed logs of all network requests and responses.

### Performance

- **CPU, Memory, FPS, Memory Leak Detector:** Monitor and analyze CPU usage, memory consumption, and frames per second in real-time.

### Resources

- **Keychain:** Inspect and manage data stored in the keychain.
- **User Defaults:** View and modify user defaults for testing different application states.
- **Files:** Access and analyze files stored by the application.

## Getting Started

### Installation

#### CocoaPods

Add the following line to your `Podfile`:

```ruby
pod 'DebugSwift', :git => 'https://github.com/DebugSwift/DebugSwift.git', :branch => 'main'
```

Then, run:

```bash
pod install
```

#### Swift Package Manager (SPM)

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/DebugSwift/DebugSwift.git", from: "main")
```

Then, add `"DebugSwift"` to your target's dependencies.

### Usage

```swift
func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    DebugSwift.setup()
    DebugSwift.show()

    return true
}
```

### Usage to show or hide with shake.
```swift
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        if motion == .motionShake {
            DebugSwift.toggle()
        }
    }
}
```

## Customization

### Network Configuration

If you want to ignore specific URLs, use the following code:

```swift
DebugSwift.Network.ignoredURLs = ["https://reqres.in/api/users/23"]
```

If you want to capture only a specific URL, use the following code:

```swift
DebugSwift.Network.onlyURLs = ["https://reqres.in/api/users/23"]
```

Adjust the URLs in the arrays according to your needs.

### App Custom Data

```swift
DebugSwift.App.customInfo = {
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
DebugSwift.App.customAction = {
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
DebugSwift.App.customControllers = {
    let controller1 = UITableViewController()
    controller1.title = "Custom TableVC 1"

    let controller2 = UITableViewController()
    controller2.title = "Custom TableVC 2"
    return [controller1, controller2]
}
```

---
### Hide Some Features
If you prefer to selectively disable certain features, DebugSwift can now deactivate unnecessary functionalities. This can assist you in development across various environments.

#### Usage

```swift
func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    DebugSwift.setup(hideFeatures: [.resources,.performance,.interface,.app]) // Example usage for hide resources, performance, interface & app
    DebugSwift.show()

    return true
}
```
#### Results:
![image9](https://github.com/DebugSwift/DebugSwift/assets/31082311/a1261022-c193-40c9-999f-80129b34dda0)

---

### Collect Memory Leaks
Get the data from memory leaks in the app.

#### Usage

```swift
DebugSwift.Performance.LeakDetector.onDetect { data in
    // If you want to send data to some analytics

    print(data.message) // Retuns the name of the class and the error
    print(data.controller) // If is an controller leak
    print(data.view) // If is an view leak
    print(data.isDeallocation) // If is an deallocation of leak (good for false/positive)
}
```

#### Results:
![image12](https://github.com/DebugSwift/DebugSwift/assets/31082311/e9acc5c5-83d4-487d-bd7e-8a66dfbc3b21)

---
### Change Appearance
Dynamic Theme: Easily Change the Interface Appearance from Dark to Light, Customize According to Your Needs.

#### Usage

```swift
func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    DebugSwift.theme(appearance: .light)
    DebugSwift.setup()
    DebugSwift.show()

    return true
}
```

#### Results:
![image7](https://github.com/DebugSwift/DebugSwift/assets/31082311/457590ce-0070-4c7a-a588-cc0825af2738)

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
