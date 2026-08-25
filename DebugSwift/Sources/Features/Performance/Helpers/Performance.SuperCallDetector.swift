//
//  Performance.SuperCallDetector.swift
//  DebugSwift
//
//  Detects UIViewController lifecycle methods that fail to call their super
//  implementation.  Addresses issue #376.
//
//  Approach: swizzle viewDidLoad, viewWillAppear, viewDidAppear,
//  viewWillDisappear and viewDidDisappear using IMP-replacement (NOT
//  method_exchangeImplementations).  Per-instance lifecycle state is tracked
//  via an associated object.  When a later lifecycle method fires for a VC
//  instance but an earlier one was never recorded, the earlier method is
//  flagged as missing a super call.
//

import UIKit

/// A single missing-super-call violation reported by ``SuperCallDetector``.
public struct SuperCallViolation: Sendable {
    /// The view-controller class whose override did not call super.
    public let className: String
    /// The lifecycle method that was expected to fire but didn't.
    public let methodName: String
    /// The method that *did* fire, revealing the missing super call.
    public let revealedBy: String
    /// When the violation was detected.
    public let timestamp: Date

    init(className: String, methodName: String, revealedBy: String, timestamp: Date = Date()) {
        self.className = className
        self.methodName = methodName
        self.revealedBy = revealedBy
        self.timestamp = timestamp
    }

    public var message: String {
        "\(className) does not call super.\(methodName)() — revealed by \(revealedBy)()"
    }
}

// MARK: - Detector

/// Thread-safe singleton that stores detected violations and callbacks.
final class SuperCallDetector: @unchecked Sendable {

    // MARK: Singleton

    private init() {}
    static let shared = SuperCallDetector()

    // MARK: Callbacks

    /// Called on the main thread whenever a new violation is detected.
    var callback: ((SuperCallViolation) -> Void)?

    // MARK: Storage

    private let lock = NSLock()
    private var _violations: [SuperCallViolation] = []
    private var _ignoredClassNames: Set<String> = []

    var violations: [SuperCallViolation] {
        lock.lock(); defer { lock.unlock() }
        return _violations
    }

    var ignoredClassNames: Set<String> {
        lock.lock(); defer { lock.unlock() }
        return _ignoredClassNames
    }

    func ignoreClass(_ name: String) {
        lock.lock(); defer { lock.unlock() }
        _ignoredClassNames.insert(name)
    }

    func setIgnoredClasses(_ names: Set<String>) {
        lock.lock(); defer { lock.unlock() }
        _ignoredClassNames = names
    }

    func clearViolations() {
        lock.lock(); defer { lock.unlock() }
        _violations.removeAll()
    }

    // MARK: Reporting

    /// Records a violation if it hasn't been recorded already for this
    /// class+method pair and the class isn't ignored.
    func reportViolation(_ violation: SuperCallViolation) {
        lock.lock()
        let isIgnored = _ignoredClassNames.contains(violation.className)
        let alreadyReported = _violations.contains {
            $0.className == violation.className && $0.methodName == violation.methodName
        }
        if !isIgnored && !alreadyReported {
            _violations.append(violation)
        }
        lock.unlock()

        if !isIgnored && !alreadyReported {
            DispatchQueue.main.async { [weak self] in
                self?.callback?(violation)
                Debug.print("🚨 SuperCallDetector: \(violation.message)")
            }
        }
    }
}

// MARK: - Lifecycle tracking (per-instance associated object)

private final class LifecycleTracker: NSObject {
    /// Ordered bitfield of lifecycle events that have fired for this instance.
    /// Bit positions match the ``LifecycleEvent`` order.
    var events: UInt8 = 0
}

/// The five swizzled lifecycle events, in lifecycle order.
enum LifecycleEvent: Int, CaseIterable {
    case viewDidLoad = 0
    case viewWillAppear = 1
    case viewDidAppear = 2
    case viewWillDisappear = 3
    case viewDidDisappear = 4

    var selector: Selector {
        switch self {
        case .viewDidLoad:               return #selector(UIViewController.viewDidLoad)
        case .viewWillAppear:            return #selector(UIViewController.viewWillAppear(_:))
        case .viewDidAppear:             return #selector(UIViewController.viewDidAppear(_:))
        case .viewWillDisappear:         return #selector(UIViewController.viewWillDisappear(_:))
        case .viewDidDisappear:          return #selector(UIViewController.viewDidDisappear(_:))
        }
    }

    var methodName: String {
        switch self {
        case .viewDidLoad:           return "viewDidLoad"
        case .viewWillAppear:        return "viewWillAppear"
        case .viewDidAppear:         return "viewDidAppear"
        case .viewWillDisappear:     return "viewWillDisappear"
        case .viewDidDisappear:      return "viewDidDisappear"
        }
    }
}

// MARK: - Swizzling

extension UIViewController {

    /// Swizzles all five lifecycle methods using IMP-replacement.  Safe to
    /// call multiple times (idempotent via a single dispatch-once token).
    static func db_swizzleLifecycleForSuperCallDetection() {
        DispatchQueue.once(token: "debugswift.uiviewcontroller.db_swizzleLifecycleForSuperCallDetection") {
            for event in LifecycleEvent.allCases {
                swizzleLifecycleIMP(for: event)
            }
        }
    }

    /// IMP-replacement swizzle for a single lifecycle method.
    ///
    /// We use ``method_setImplementation`` rather than
    /// ``method_exchangeImplementations`` to avoid creating renamed selectors
    /// on `UIViewController`.  Third-party agents (e.g. NewRelic) scan method
    /// tables and crash (`NRInvalidArgumentException`) when they find
    /// unexpected selectors on core UIKit classes.  See
    /// `UIWindowScene+.swift` `db_swizzleViewDidAppear()` for the same
    /// technique applied to `viewDidAppear`.
    private static func swizzleLifecycleIMP(for event: LifecycleEvent) {
        guard let originalMethod = class_getInstanceMethod(
            UIViewController.self,
            event.selector
        ) else { return }

        // Capture the original IMP before we replace it.
        let originalIMP = method_getImplementation(originalMethod)

        switch event {
        case .viewDidLoad:
            db_originalViewDidLoadIMP = originalIMP
            let block: @convention(block) (UIViewController) -> Void = { vc in
                vc.db_invokeOriginalLifecycleIMP(event, originalIMP)
                vc.db_recordLifecycleEvent(event)
            }
            method_setImplementation(originalMethod, imp_implementationWithBlock(block))

        case .viewWillAppear:
            db_originalViewWillAppearIMP = originalIMP
            let block: @convention(block) (UIViewController, Bool) -> Void = { vc, animated in
                vc.db_invokeOriginalLifecycleIMP(event, originalIMP, animated)
                vc.db_recordLifecycleEvent(event)
            }
            method_setImplementation(originalMethod, imp_implementationWithBlock(block))

        case .viewDidAppear:
            db_originalViewDidAppearForSuperIMP = originalIMP
            let block: @convention(block) (UIViewController, Bool) -> Void = { vc, animated in
                vc.db_invokeOriginalLifecycleIMP(event, originalIMP, animated)
                vc.db_recordLifecycleEvent(event)
            }
            method_setImplementation(originalMethod, imp_implementationWithBlock(block))

        case .viewWillDisappear:
            db_originalViewWillDisappearIMP = originalIMP
            let block: @convention(block) (UIViewController, Bool) -> Void = { vc, animated in
                vc.db_invokeOriginalLifecycleIMP(event, originalIMP, animated)
                vc.db_recordLifecycleEvent(event)
            }
            method_setImplementation(originalMethod, imp_implementationWithBlock(block))

        case .viewDidDisappear:
            db_originalViewDidDisappearForSuperIMP = originalIMP
            let block: @convention(block) (UIViewController, Bool) -> Void = { vc, animated in
                vc.db_invokeOriginalLifecycleIMP(event, originalIMP, animated)
                vc.db_recordLifecycleEvent(event)
            }
            method_setImplementation(originalMethod, imp_implementationWithBlock(block))
        }
    }
}

// MARK: - Stored original IMPs

extension UIViewController {
    /// `nonisolated(unsafe)` — each is written exactly once (guarded by
    /// `DispatchQueue.once`) and only read afterward.
    nonisolated(unsafe) static var db_originalViewDidLoadIMP: IMP?
    nonisolated(unsafe) static var db_originalViewWillAppearIMP: IMP?
    nonisolated(unsafe) static var db_originalViewDidAppearForSuperIMP: IMP?
    nonisolated(unsafe) static var db_originalViewWillDisappearIMP: IMP?
    nonisolated(unsafe) static var db_originalViewDidDisappearForSuperIMP: IMP?
}

// MARK: - Per-instance tracking helpers

extension UIViewController {

    private static var trackerKey: UInt8 = 0

    /// Returns (or lazily creates) the lifecycle tracker associated with
    /// this VC instance.
    private var db_lifecycleTracker: LifecycleTracker {
        if let existing = objc_getAssociatedObject(self, &Self.trackerKey) as? LifecycleTracker {
            return existing
        }
        let tracker = LifecycleTracker()
        objc_setAssociatedObject(self, &Self.trackerKey, tracker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return tracker
    }

    /// Records that `event` fired for this instance, then checks whether any
    /// earlier lifecycle event was *skipped* (i.e. its bit is still clear).
    /// A skipped earlier event means the subclass override for that event
    /// did not call super.
    func db_recordLifecycleEvent(_ event: LifecycleEvent) {
        let tracker = db_lifecycleTracker
        let bit: UInt8 = 1 << event.rawValue

        // Check which earlier events have NOT fired yet.
        let earlierMask: UInt8 = (1 << event.rawValue) - 1   // bits 0…event-1
        let missing = (~tracker.events) & earlierMask

        // Record this event.
        tracker.events |= bit

        guard missing != 0 else { return }

        // Report a violation for each missing earlier event.
        let className = String(describing: type(of: self))
        for earlier in LifecycleEvent.allCases where earlier.rawValue < event.rawValue {
            if missing & (1 << earlier.rawValue) != 0 {
                SuperCallDetector.shared.reportViolation(
                    .init(
                        className: className,
                        methodName: earlier.methodName,
                        revealedBy: event.methodName
                    )
                )
            }
        }
    }

    /// Invokes the original implementation captured before swizzling.
    func db_invokeOriginalLifecycleIMP(_ event: LifecycleEvent, _ imp: IMP) {
        typealias VoidIMP = @convention(c) (UIViewController, Selector) -> Void
        let casted = unsafeBitCast(imp, to: VoidIMP.self)
        casted(self, event.selector)
    }

    /// Invokes the original implementation (animated variant) captured before
    /// swizzling.
    func db_invokeOriginalLifecycleIMP(_ event: LifecycleEvent, _ imp: IMP, _ animated: Bool) {
        typealias AnimatedIMP = @convention(c) (UIViewController, Selector, Bool) -> Void
        let casted = unsafeBitCast(imp, to: AnimatedIMP.self)
        casted(self, event.selector, animated)
    }
}
