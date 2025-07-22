# 🚨 DebugSwift Console Interception Deadlock Bug

## Overview

This directory contains reproduction cases and fixes for a critical deadlock bug in DebugSwift v1.7.2 where console interception causes UI freezes after multiple network requests.

## The Bug

**Symptoms:**
- UI completely freezes after 25-30 network requests
- Main thread blocked in `__psynch_mutexwait` 
- Deadlock occurs in Swift's `print()` function
- Application becomes unresponsive

**Root Cause:**
DebugSwift's console interception (`StdoutCapture.swift`) redirects STDOUT using `dup2()`, which creates mutex contention when multiple threads call `print()` simultaneously. The redirected stdout file descriptor causes `flockfile()` to deadlock.

**Stack Trace:**
```
Thread 1 Queue : com.apple.main-thread (serial)
#0  __psynch_mutexwait ()
#1  _pthread_mutex_firstfit_lock_wait ()
#2  pthread_mutex_firstfit_lock_slow ()
#3  flockfile ()
#4  Swift.print(: Any..., separator: Swift.String, terminator: Swift.String) -> ()
```

## Reproduction Steps

### Method 1: Using DeadlockTestView

1. **Run the app with current setup:**
   ```swift
   // Current buggy setup in ExampleApp.swift
   debugSwift.setup().show()  // Console interception enabled
   ```

2. **Navigate to "🚨 Console Deadlock Test"** in the example app

3. **Tap "Start Deadlock Test"** - this will:
   - Launch 50 concurrent network requests
   - Each request makes 6+ `print()` statements
   - UI should freeze around request 25-30

4. **Observe the deadlock:**
   - UI becomes completely unresponsive
   - Request counter stops updating
   - App requires force-quit to recover

### Method 2: Manual Testing

Add this code to any view controller and run it:

```swift
func reproduceDeadlock() {
    Task {
        await withTaskGroup(of: Void.self) { group in
            for i in 1...50 {
                group.addTask {
                    print("🚀 Starting request \(i)")
                    // Make network request with more print statements
                    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        print("✅ Request \(i) completed: \(data.count) bytes")
                    } catch {
                        print("❌ Request \(i) failed: \(error)")
                    }
                    print("🏁 Request \(i) finished")
                }
            }
        }
    }
}
```

## The Fix

### Simple Fix: Disable Console Interception

```swift
// In AppDelegate or App setup
debugSwift
    .setup(
        disable: [.console]  // 🔥 This prevents the deadlock
    )
    .show()
```

### Complete Fixed Example

See `ExampleAppFixed.swift` for a complete working example:

```swift
class AppDelegateFixed: NSObject, UIApplicationDelegate {
    private let debugSwift = DebugSwift()

    func application(/* ... */) -> Bool {
        // ✅ FIXED: Disable console interception to prevent deadlock
        debugSwift
            .setup(
                disable: [.console]  // This prevents the console interception deadlock
            )
            .show()
        
        return true
    }
}
```

## What You Lose vs Keep

### ❌ You'll Lose:
- Console log capture in DebugSwift's "Console" tab
- Ability to view `print()` statements within DebugSwift UI

### ✅ You'll Keep:
- **All network monitoring** (HTTP + WebSocket)
- **Performance monitoring** (CPU, Memory, FPS)
- **Interface debugging** tools
- **Resource inspection** (Files, UserDefaults, Keychain, etc.)
- **App information** and custom actions
- **No more UI freezes** after 25-30 requests

## Alternative Solutions

### Option 1: Custom Logging (Recommended)
```swift
// Replace print() with custom logger that bypasses stdout redirection
class DebugLogger {
    static func log(_ message: String) {
        // Direct write to stderr (not captured by DebugSwift)
        fputs("\(message)\n", stderr)
        
        // Or use os_log
        os_log("%@", message)
    }
}

// In your code:
DebugLogger.log("This won't cause deadlock")
```

### Option 2: Conditional Console Capture
```swift
// Only enable console capture when not doing heavy network operations
let isNetworkTestingMode = ProcessInfo.processInfo.arguments.contains("--network-testing")
debugSwift.setup(
    disable: isNetworkTestingMode ? [.console] : []
)
```

## Testing the Fix

### Using ExampleAppFixed.swift

1. **To test the fixed version:**
   - Rename `ExampleApp.swift` → `ExampleAppBuggy.swift`
   - Rename `ExampleAppFixed.swift` → `ExampleApp.swift` 
   - Update `@main` to point to `ExampleAppFixed`

2. **Run the deadlock test again:**
   - Navigate to "🚨 Console Deadlock Test"
   - Tap "Start Deadlock Test" 
   - **Expected result:** All 50 requests complete without UI freeze

### Verification Checklist

- [ ] No UI freezes after 25-30+ network requests
- [ ] Network monitoring still works perfectly
- [ ] All other DebugSwift features remain functional
- [ ] Console logs appear in Xcode console (just not in DebugSwift UI)
- [ ] App remains responsive during heavy network activity

## Technical Deep Dive

### The Problem in Detail

1. **STDOUT Redirection:** `StdoutCapture.openConsolePipe()` uses `dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)` to redirect stdout
2. **Mutex Contention:** Swift's `print()` calls `flockfile()` on the redirected file descriptor for thread safety
3. **Concurrent Access:** Multiple network requests calling `print()` simultaneously create mutex contention
4. **Deadlock:** The pipe's file descriptor mutex becomes contended, main thread blocks waiting for mutex
5. **UI Freeze:** Main thread can't process UI updates while blocked on stdio mutex

### Why This Affects Network Requests Specifically

Network requests typically involve:
- Multiple concurrent URLSession tasks
- Error handling with `print()` statements
- Success logging with `print()` statements  
- Status updates on main thread with `print()` statements

This creates the perfect storm for stdio mutex contention.

## Reporting to DebugSwift Team

This is a critical bug that should be reported to the DebugSwift maintainers:

1. **Repository:** https://github.com/DebugSwift/DebugSwift
2. **Bug Report Should Include:**
   - Version: 1.7.2
   - Issue: Console interception deadlock
   - Stack trace provided above
   - Reproduction case in this folder

## Long-term Solution

The DebugSwift team should:

1. **Fix the console interception mechanism** to avoid stdio mutex contention
2. **Add a safer console capture method** that doesn't redirect STDOUT
3. **Provide a runtime toggle** for console interception
4. **Add deadlock detection** with automatic recovery

## Files in This Example

- `DeadlockTestView.swift` - SwiftUI view to reproduce the deadlock
- `ExampleAppFixed.swift` - Fixed app delegate with console disabled
- `DEADLOCK_REPRODUCTION.md` - This documentation
- `ContentView.swift` - Updated to include deadlock test navigation

---

**⚠️ Warning:** Always test the deadlock reproduction on a physical device or simulator you can easily restart, as the deadlock requires a force-quit to recover. 