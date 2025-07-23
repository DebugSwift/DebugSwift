//
//  DebugSwift.Performance.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public enum Performance {
        public static let shared = PerformanceManager()
        
        /// Chart configuration for performance monitoring
        public enum Chart {
            /// Time window in seconds for performance charts (default: 120 seconds = 2 minutes)
            nonisolated(unsafe) public static var timeWindowSeconds: Double = 120.0
            
            /// Set the time window for performance charts
            /// - Parameter seconds: Time window in seconds (e.g., 60 for 1 minute, 120 for 2 minutes, 300 for 5 minutes)
            public static func setTimeWindow(seconds: Double) {
                timeWindowSeconds = max(10.0, seconds) // Minimum 10 seconds
            }
            
            /// Set the time window for performance charts
            /// - Parameter minutes: Time window in minutes (e.g., 1.0 for 1 minute, 2.0 for 2 minutes)
            public static func setTimeWindow(minutes: Double) {
                setTimeWindow(seconds: minutes * 60.0)
            }
        }
        
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
        
        public enum ThreadChecker {
            /// Enable thread violation detection
            public static func enable() {
                PerformanceThreadChecker.shared.enable()
            }
            
            /// Disable thread violation detection
            public static func disable() {
                PerformanceThreadChecker.shared.disable()
            }
            
            /// Enable automatic fixing of thread violations
            public static func enableAutoFix() {
                PerformanceThreadChecker.shared.enableAutoFix()
            }
            
            /// Configure visual alerts
            public static func setShowVisualAlerts(_ enabled: Bool) {
                PerformanceThreadChecker.shared.showVisualAlerts = enabled
            }
            
            /// Configure console logging
            public static func setLogToConsole(_ enabled: Bool) {
                PerformanceThreadChecker.shared.logToConsole = enabled
            }
            
            /// Add a class to ignore list
            public static func ignoreClass(_ className: String) {
                PerformanceThreadChecker.shared.ignoredClasses.insert(className)
            }
            
            /// Remove a class from ignore list
            public static func unignoreClass(_ className: String) {
                PerformanceThreadChecker.shared.ignoredClasses.remove(className)
            }
            
            /// Set multiple ignored classes
            public static func setIgnoredClasses(_ classNames: [String]) {
                PerformanceThreadChecker.shared.ignoredClasses = Set(classNames)
            }
            
            /// Clear all recorded violations
            public static func clearViolations() {
                PerformanceThreadChecker.shared.clearViolations()
            }
        }
    }
}

// MARK: - Performance Manager

public class PerformanceManager: @unchecked Sendable {
    public let leakDetector = DebugSwift.Performance.LeakDetector()
    
    internal init() {}
    
    // MARK: - Leak Detection (Legacy Support)
    
    private var leakCallbacks: [(LeakData) -> Void] = []
    
    public func onLeakDetected(_ callback: @escaping (LeakData) -> Void) {
        leakCallbacks.append(callback)
    }
    
    internal func reportLeak(_ data: LeakData) {
        for callback in leakCallbacks {
            callback(data)
        }
    }
    
    public struct LeakData: Sendable {
        public let message: String
        public let controller: String?
        public let view: String?
        public let isDeallocation: Bool
        
        public init(message: String, controller: String? = nil, view: String? = nil, isDeallocation: Bool = false) {
            self.message = message
            self.controller = controller
            self.view = view
            self.isDeallocation = isDeallocation
        }
    }
}

// MARK: - Public Types

extension DebugSwift.Performance {
    public enum AutoFixMode: String, CaseIterable, Sendable {
        case disabled = "Disabled"
        case logOnly = "Log Only"
        case autoFix = "Auto Fix"
        
        public var description: String {
            switch self {
            case .disabled: return "Detection disabled"
            case .logOnly: return "Log violations without fixing"
            case .autoFix: return "Automatically dispatch to main thread"
            }
        }
        
        var internalMode: PerformanceThreadChecker.AutoFixMode {
            switch self {
            case .disabled: return .disabled
            case .logOnly: return .logOnly
            case .autoFix: return .autoFix
            }
        }
    }
    
    public struct ThreadViolation: Sendable {
        public let id: UUID
        public let timestamp: Date
        public let methodName: String
        public let className: String
        public let threadName: String
        public let stackTrace: [String]
        public let severity: Severity
        
        public enum Severity: String, CaseIterable, Sendable {
            case warning = "Warning"
            case error = "Error"
            case critical = "Critical"
            
            public var emoji: String {
                switch self {
                case .warning: return "⚠️"
                case .error: return "❌"
                case .critical: return "🚨"
                }
            }
        }
        
        init(_ data: PerformanceThreadChecker.ThreadViolation) {
            self.id = data.id
            self.timestamp = data.timestamp
            self.methodName = data.methodName
            self.className = data.className
            self.threadName = data.threadName
            self.stackTrace = data.stackTrace
            self.severity = Severity(rawValue: data.severity.rawValue) ?? .warning
        }
    }
}
