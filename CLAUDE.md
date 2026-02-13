# DebugSwift Project Instructions

## Project Overview
DebugSwift is an iOS debugging toolkit written in Swift that provides comprehensive debugging features including network monitoring, performance analysis, UI inspection, and resource management for iOS applications.

## Key Technologies
- Swift 6.0+
- iOS 14.0+
- UIKit with SwiftUI support
- CocoaPods distribution

## Project Structure
- `DebugSwift/Sources/` - Main source code
  - `Base/` - Base controllers and foundational classes
  - `Features/` - Core debugging features (App, Interface, Network, Performance, Resources)
  - `Helpers/` - Utilities, extensions, and managers
  - `Settings/` - Configuration and feature settings
- `Example/` - Demo application
- `DebugSwift.podspec` - CocoaPods specification

## Development Guidelines

### Test-Driven Development (TDD)
- **ALWAYS follow TDD**: Write tests before implementation
- Write failing test → Make it pass → Refactor
- Use descriptive test names that explain behavior
- Test all public APIs and critical functionality
- Mock external dependencies for unit tests
- Prefer parameterized tests for multiple scenarios

### Code Style
- Follow Swift naming conventions
- Use proper access control (internal, private, public)
- Prefer composition over inheritance
- Use extensions to organize code by functionality
- Add meaningful documentation for public APIs

### Architecture Patterns
- Feature-based modular architecture
- Each feature has its own controller and view model when needed
- Managers handle cross-cutting concerns (FileManager, WindowManager, etc.)
- Settings classes configure individual features

### Key Components
- **BaseController**: Foundation for all feature controllers
- **TabBarController**: Main interface navigation
- **FloatingButton**: Entry point UI element
- **WindowManager**: Handles overlay windows and presentation
- **DebugSwift**: Main configuration and setup class

### Testing
- Run tests with the Example project
- Test on iOS 14.0+ devices and simulators
- Verify features work in both UIKit and SwiftUI contexts

### Performance Considerations
- Debugging tools should have minimal impact on app performance
- Use lazy initialization for heavy components
- Memory leak detection should not create leaks itself
- Network monitoring should be efficient and filterable

### Security & Privacy
- Never log sensitive user data
- Respect app sandbox boundaries
- Handle keychain access securely
- Provide opt-out mechanisms for privacy-sensitive features

### Distribution
- Maintain CocoaPods compatibility
- Keep Swift Package Manager support up to date
- Version according to semantic versioning
- Update podspec version for releases

## Common Tasks
- Adding new debugging features goes in `Features/`
- UI extensions go in `Helpers/Extensions/`
- Cross-cutting utilities go in `Helpers/Tools/`
- Feature configuration goes in `Settings/`

## Build Commands
```bash
# Build the framework
swift build

# Run tests
xcodebuild test -scheme DebugSwift -destination 'platform=iOS Simulator,name=iPhone 14'

# Update CocoaPods
pod spec lint DebugSwift.podspec
```

## Important Notes
- All debugging features should be conditionally compiled with `#if DEBUG`
- Maintain backward compatibility with iOS 14.0+
- Follow Apple's Human Interface Guidelines for UI components
- Ensure thread safety for performance monitoring components