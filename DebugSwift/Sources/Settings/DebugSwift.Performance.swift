//
//  DebugSwift.Performance.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public enum Performance {
        public class LeakDetector {
            /**
             Triggers the callback whenever a leaked `ViewController` or `View` is detected.

             - Parameters:
               - detectionDelay: The time in seconds allowed for each ViewController or View to deinitialize itself after it has been closed or removed (i.e., grace period). If the ViewController, View, or any of its subviews are still in memory after this delay, the callback will be triggered. Increasing the delay may help prevent certain false positives. The default value is 1.0 seconds, though a shorter delay may be considered for debug builds.
               - callback: This callback is triggered whenever a ViewController is closed or a View is removed but remains in memory along with any of its subviews. The callback is triggered again once the ViewController or View does deinitialize (if it ever does). It provides the leaked ViewController or View and a warning message string that you can use for logging. If the deinitialization warning is triggered, both the ViewController and View will be nil. Return true to display an alert dialog with the message. Return nil to prevent the callback from being triggered again for the same ViewController or View in future (useful if you want to ignore warnings for certain ViewControllers or Views).
             */
            public func onDetect(
                detectionDelay: TimeInterval = 1,
                callback: ((PerformanceLeak) -> Void)?
            ) {
                PerformanceLeakDetector.shared.delay = detectionDelay
                PerformanceLeakDetector.shared.callback = callback
            }

            public var ignoredWindowClassNames: [String] {
                get {
                    PerformanceLeakDetector.shared.ignoredWindowClassNames
                }
                set {
                    PerformanceLeakDetector.shared.ignoredWindowClassNames = newValue
                }
            }

            public var ignoredViewControllerClassNames: [String] {
                get {
                    PerformanceLeakDetector.shared.ignoredViewControllerClassNames
                }
                set {
                    PerformanceLeakDetector.shared.ignoredViewControllerClassNames = newValue
                }
            }

            public var ignoredViewClassNames: [String] {
                get {
                    PerformanceLeakDetector.shared.ignoredViewClassNames
                }
                set {
                    PerformanceLeakDetector.shared.ignoredViewClassNames = newValue
                }
            }
        }
    }
}
