# DebugSwiftPortable

Portable Swift core extracted from DebugSwift for non-Apple runtimes.

This package intentionally avoids UIKit, SwiftUI, Objective-C runtime hooks, and
other Apple-only frameworks. It is the layer intended for Android Swift SDK
experiments and JNI/C bridge integration.

Current scope:

- Record simple debug events.
- Produce a JSON debug snapshot.
- Share URL wildcard matching logic.
- Export C ABI functions that can be called from a JNI shim.

This is not the full DebugSwift overlay. Android UI, app hooks, and platform
inspectors belong in an Android-native shell.
