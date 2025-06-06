//
//  Performance.ThreadChecker.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit
import Foundation

public final class PerformanceThreadChecker: @unchecked Sendable {
    public static let shared = PerformanceThreadChecker()
    
    // MARK: - Types
    
    public struct ThreadViolation: Sendable {
        public let id: UUID
        public let timestamp: Date
        public let methodName: String
        public let className: String
        public let threadName: String
        public let stackTrace: [String]
        public let severity: Severity
        
        public init(methodName: String, className: String, threadName: String, stackTrace: [String], severity: Severity) {
            self.id = UUID()
            self.timestamp = Date()
            self.methodName = methodName
            self.className = className
            self.threadName = threadName
            self.stackTrace = stackTrace
            self.severity = severity
        }
        
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
            
            public var color: UIColor {
                switch self {
                case .warning: return .systemOrange
                case .error: return .systemRed
                case .critical: return .systemPurple
                }
            }
        }
    }
    
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
    }
    
    // MARK: - Properties
    
    public var isEnabled: Bool = false
    public var autoFixMode: AutoFixMode = .logOnly
    public var showVisualAlerts: Bool = true
    public var logToConsole: Bool = true
    public var ignoredClasses: Set<String> = [
        "UIView",
        "CALayer",
        "_UISystemGestureGateGestureRecognizer"
    ]
    
    private var violations: [ThreadViolation] = []
    private var violationCallbacks: [(ThreadViolation) -> Void] = []
    
    private init() {}
    
    // MARK: - Public Interface
    
    public func enable() {
        isEnabled = true
    }
    
    public func disable() {
        isEnabled = false
    }
    
    public func enableAutoFix() {
        autoFixMode = .autoFix
    }
    
    public func getViolations() -> [ThreadViolation] {
        return violations
    }
    
    public func clearViolations() {
        violations.removeAll()
    }
    
    public func onViolationDetected(_ callback: @escaping (ThreadViolation) -> Void) {
        violationCallbacks.append(callback)
    }
    
    // MARK: - Manual Thread Checking
    
    /// Manual method to check if we're on main thread and log violations
    public func checkMainThread(
        methodName: String,
        className: String,
        file: String = #file,
        line: Int = #line
    ) {
        guard isEnabled else { return }
        
        if !Thread.isMainThread {
            let violation = createViolation(
                methodName: methodName,
                className: className,
                file: file,
                line: line
            )
            handleViolation(violation)
        }
    }
    
    private func createViolation(methodName: String, className: String, file: String, line: Int) -> ThreadViolation {
        let stackTrace = Thread.callStackSymbols.prefix(10).map { $0 }
        let threadName = Thread.current.name ?? "Unknown Thread"
        
        let severity: ThreadViolation.Severity = determineSeverity(methodName: methodName)
        
        return ThreadViolation(
            methodName: methodName,
            className: className,
            threadName: threadName,
            stackTrace: Array(stackTrace),
            severity: severity
        )
    }
    
    private func determineSeverity(methodName: String) -> ThreadViolation.Severity {
        switch methodName {
        case "setNeedsLayout", "setNeedsDisplay":
            return .warning
        case "removeFromSuperview", "viewDidLoad":
            return .error
        case "addSubview", "insertSubview":
            return .critical
        default:
            return .warning
        }
    }
    
    private func handleViolation(_ violation: ThreadViolation) {
        // Store violation
        violations.append(violation)
        
        // Trigger callbacks
        for callback in violationCallbacks {
            callback(violation)
        }
        
        // Log to console
        if logToConsole {
            logViolationToConsole(violation)
        }
        
        // Show visual alert
        if showVisualAlerts {
            DispatchQueue.main.async { [weak self] in
                self?.showVisualViolationAlert(violation)
            }
        }
    }
    
    private func logViolationToConsole(_ violation: ThreadViolation) {
        let message = """
        \(violation.severity.emoji) [MainThreadChecker]: UI update detected off main thread
        - Method: \(violation.methodName)
        - Class: \(violation.className)
        - Thread: \(violation.threadName)
        - Severity: \(violation.severity.rawValue)
        - Stack Trace:
        \(violation.stackTrace.prefix(5).joined(separator: "\n"))
        """
        
        Debug.print(message)
    }
    
    @MainActor private func showVisualViolationAlert(_ violation: ThreadViolation) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let banner = ThreadViolationBanner(violation: violation)
        window.addSubview(banner)
        
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
            banner.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: window.trailingAnchor)
        ])
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3) {
                banner.alpha = 0
            } completion: { _ in
                banner.removeFromSuperview()
            }
        }
    }
} 