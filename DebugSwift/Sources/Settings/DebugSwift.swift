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

extension DebugSwift {
    public enum Network {
        public static var ignoredURLs = [String]()
        public static var onlyURLs = [String]()
    }

    public enum App {
        public static var customInfo: (() -> [CustomData])?
        public static var customAction: (() -> [CustomAction])?
        public static var customControllers: (() -> [UIViewController])?
    }

    public enum Console {
        public static var ignoredLogs = [String]()
        public static var onlyLogs = [String]()
    }

    public enum Performance {
        public enum LeakDetector {
            /**
             Triggers the callback whenever a leaked ViewController or View is detected.

             - Parameter detectionDelay: The time in seconds allowed for each ViewController or View to deinit itself after it has been closed/removed (i.e. grace period). If it or any of its subviews are still in memory (alive) after the delay the callback will be triggered. Increasing the delay may prevent certain false positives. The default 1.0s is recommended, though a tighter delay may be considered for debug builds.
             - Parameter callback: This will be triggered every time a ViewController closes or View is removed but it or one of its subviews don't deinit. It will trigger again once it does deinit (if ever). It either provides the ViewController or the View that has leaked and a warning message string that you can use to log. The provided ViewController and View will both be nil in case of a deinit warning. Return true to show an alert dialog with the message. Return nil if you want to prevent a future deinit of the ViewController or View from triggering the callback again (useful if you want to ignore warnings of certain ViewControllers/Views).
             */
            public static func onDetect(
                detectionDelay: TimeInterval = 1.0,
                callback: ((PerformanceLeak) -> Void)?
            ) {
                PerformanceLeakDetector.delay = detectionDelay
                PerformanceLeakDetector.callback = callback
            }

            public static let ignoredWindowClassNames: [String] = [
                "UIRemoteKeyboardWindow",
                "UITextEffectsWindow"
            ]

            public static let ignoredViewControllerClassNames: [String] = [
                "UICompatibilityInputViewController",
                "_SFAppPasswordSavingViewController",
                "UIKeyboardHiddenViewController_Save",
                "_UIAlertControllerTextFieldViewController",
                "UISystemInputAssistantViewController",
                "UIPredictionViewController",
                "DebugSwift.TabBarController"
            ]

            public static let ignoredViewClassNames: [String] = [
                "PLTileContainerView",
                "CAMPreviewView",
                "_UIPointerInteractionAssistantEffectContainerView"
            ]

        }
    }

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
