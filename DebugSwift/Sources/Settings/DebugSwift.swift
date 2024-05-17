//
//  DebugSwift.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

public enum DebugSwift {
    public static func setup() {
        LocalizationManager.shared.loadBundle()
        FeatureHandling.shared.selectedFeatureHandler(viewController: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.setup(TabBarController())
        }

        LaunchTimeTracker.measureAppStartUpTime()
    }

    public static func setup(hideFeatures: [DebugSwiftFeatures]) {
        FeatureHandling.shared.hide(features: hideFeatures)
    }

    public static func show() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.show()
        }
    }

    public static func hide() {
        FloatViewManager.remove()
    }

    public static func toggle() {
        FloatViewManager.toggle()
    }

    public static func theme(appearance: Appearance) {
        Theme.shared.setAppearance(appearance: appearance)
    }

    @available(*, deprecated, renamed: "Debug.enable", message: "Use now Debug.enable")
    public static func toggleDebugger(_ enable: Bool) {
        Debug.enable = enable
    }
}

// MARK: - Network

extension DebugSwift {
    public enum Network {
        public static var ignoredURLs = [String]()
        public static var onlyURLs = [String]()
    }
}

// MARK: - App

extension DebugSwift {
    public enum App {
        public static var customInfo: (() -> [CustomData])?
        public static var customAction: (() -> [CustomAction])?
        public static var customControllers: (() -> [UIViewController])?
    }
}

// MARK: - Console

extension DebugSwift {
    public enum Console {
        public static var ignoredLogs = [String]()
        public static var onlyLogs = [String]()
    }
}

// MARK: - Debugger

extension DebugSwift {
    public enum Debugger {
        /// Enable/Disable logs in Xcode console
        public static var logEnable: Bool {
            get {
                Debug.enable
            } set {
                Debug.enable = newValue
            }
        }

        /// Enable/Disable `ImpactFeedback`
        public static var feedbackEnable: Bool {
            get {
                ImpactFeedback.enable
            } set {
                ImpactFeedback.enable = newValue
            }
        }
    }
}

// MARK: - Performance

extension DebugSwift {
    public enum Performance {
        public enum LeakDetector {
            /**
             Triggers the callback whenever a leaked `ViewController` or `View` is detected.

             - Parameters:
               - detectionDelay: The time in seconds allowed for each ViewController or View to deinitialize itself after it has been closed or removed (i.e., grace period). If the ViewController, View, or any of its subviews are still in memory after this delay, the callback will be triggered. Increasing the delay may help prevent certain false positives. The default value is 1.0 seconds, though a shorter delay may be considered for debug builds.
               - callback: This callback is triggered whenever a ViewController is closed or a View is removed but remains in memory along with any of its subviews. The callback is triggered again once the ViewController or View does deinitialize (if it ever does). It provides the leaked ViewController or View and a warning message string that you can use for logging. If the deinitialization warning is triggered, both the ViewController and View will be nil. Return true to display an alert dialog with the message. Return nil to prevent the callback from being triggered again for the same ViewController or View in future (useful if you want to ignore warnings for certain ViewControllers or Views).
             */
            public static func onDetect(
                detectionDelay: TimeInterval = 1,
                callback: ((PerformanceLeak) -> Void)?
            ) {
                PerformanceLeakDetector.delay = detectionDelay
                PerformanceLeakDetector.callback = callback
            }

            public static var ignoredWindowClassNames: [String] {
                get {
                    PerformanceLeakDetector.ignoredWindowClassNames
                }
                set {
                    PerformanceLeakDetector.ignoredWindowClassNames = newValue
                }
            }

            public static var ignoredViewControllerClassNames: [String] {
                get {
                    PerformanceLeakDetector.ignoredViewControllerClassNames
                }
                set {
                    PerformanceLeakDetector.ignoredViewControllerClassNames = newValue
                }
            }

            public static var ignoredViewClassNames: [String] {
                get {
                    PerformanceLeakDetector.ignoredViewClassNames
                }
                set {
                    PerformanceLeakDetector.ignoredViewClassNames = newValue
                }
            }
        }
    }
}
