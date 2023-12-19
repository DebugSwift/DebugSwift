# DebugSwift Toolkit

DebugSwift is a comprehensive toolkit designed to simplify and enhance the debugging process for Swift-based applications. Whether you're troubleshooting issues or optimizing performance, DebugSwift provides a set of powerful features to make your debugging experience more efficient.

![image1](https://github.com/MaatheusGois/DebugSwift/assets/31082311/03d0e0d0-d2ab-4fc2-8d47-e7089fffc2f6)
![image2](https://github.com/MaatheusGois/DebugSwift/assets/31082311/994e75c9-948e-486b-9522-4e2a9779de4e)
![image3](https://github.com/MaatheusGois/DebugSwift/assets/31082311/0aebb4ce-3e0c-4eea-b2a4-4516d916228e)
![image4](https://github.com/MaatheusGois/DebugSwift/assets/31082311/fecff545-405b-493f-99f8-3ed65d453227)

## Features

### App Settings

- **Change Location:** Simulate different locations for testing location-based features.
- **Crash Reports:** Access detailed crash reports for analysis and debugging.
- **Console:** Monitor and interact with the application's console logs.
- **Version:** View the current application version.
- **Build:** Identify the application's build number.
- **Bundle Name:** Retrieve the application's bundle name.
- **Bundle ID:** Display the unique bundle identifier for the application.
- **Server:** Switch between different server environments.
- **Device Infos:** Access information about the device running the application.

### Interface

- **Grid:** Overlay a grid on the interface to assist with layout alignment.
- **Slow Animations:** Slow down animations for better visualization and debugging.
- **Showing Touches:** Highlight touch events for easier interaction tracking.
- **Colorized View with Borders:** Apply colorization and borders to views for improved visibility.

### Network Logs

- **All Response/Request Logs:** Capture and review detailed logs of all network requests and responses.

### Performance

- **CPU, Memory, FPS:** Monitor and analyze CPU usage, memory consumption, and frames per second in real-time.

### Resources

- **Keychain:** Inspect and manage data stored in the keychain.
- **User Defaults:** View and modify user defaults for testing different application states.
- **Files:** Access and analyze files stored by the application.

## Getting Started

### Installation

#### CocoaPods

Add the following line to your `Podfile`:

```ruby
pod 'DebugSwift', :git => 'https://github.com/MaatheusGois/DebugSwift.git', :branch => 'main'
```

Then, run:

```bash
pod install
```

#### Swift Package Manager (SPM)

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/MaatheusGois/DebugSwift.git", from: "main")
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

## Customization

### Network Configuration

To ingnore some url:
```swift
DebugSwift.Network.ignoredURLs = ["https://reqres.in/api/users/23"]
```

To only get this url:
```swift
DebugSwift.Network.onlyURLs = ["https://reqres.in/api/users/23"]
```

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


![image5](https://github.com/MaatheusGois/DebugSwift/assets/31082311/2481f7b9-2592-46be-b1d7-c0787fcd9110)



## Contributing

Contributions are welcome! If you have suggestions, improvements, or bug fixes, please submit a pull request. Let's make DebugSwift even more powerful together!

## License

DebugSwift is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
