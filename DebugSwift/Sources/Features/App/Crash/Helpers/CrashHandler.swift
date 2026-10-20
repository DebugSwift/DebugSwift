//
//  CrashHandler.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import Foundation

public class CrashUncaughtExceptionHandler: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _exceptionReceiveClosure: ((Int32?, NSException?, String, [String]) -> Void)?

    /// Best-effort, immediate notification on the exception's thread. Keep it short:
    /// do not wait on other threads/locks. A contended callback lock skips delivery.
    /// Setting this never controls whether the library attempts to save the report.
    public static var exceptionReceiveClosure: ((Int32?, NSException?, String, [String]) -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _exceptionReceiveClosure
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _exceptionReceiveClosure = newValue
        }
    }

    public func prepare() {
        // Initialize observer/lock storage during normal execution, never lazily
        // for the first time on an uncaught-exception path.
        _ = Self.exceptionReceiveClosure
        ExceptionCrashCapture.shared.prepare()
    }

    static func callbackIfAvailable() -> ((Int32?, NSException?, String, [String]) -> Void)? {
        guard lock.try() else { return nil }
        defer { lock.unlock() }
        return _exceptionReceiveClosure
    }
}

// swiftlint:disable:next identifier_name
func UncaughtExceptionHandler(exception: NSException) {
    let arr = exception.callStackSymbols
    let reason = exception.reason ?? ""
    let name = exception.name.rawValue
    let crash = "\nName: \(name)\nReason: \(reason)"

    let callback = CrashUncaughtExceptionHandler.callbackIfAvailable()
    ExceptionCrashCapture.shared.persist(name: crash, symbols: arr)
    callback?(nil, exception, crash, arr)
}

public class CrashSignalExceptionHandler: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)?

    /// Delivered during the next launch, after the pending signal report has been persisted.
    /// Swift callbacks are never executed in a POSIX signal context.
    /// Register before the first prepare() / DebugSwift.setup(). Delivery is synchronous
    /// on the preparing thread; later registration does not replay recovered reports.
    /// No notification is delivered for records that could not be persisted.
    public static var exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _exceptionReceiveClosure
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _exceptionReceiveClosure = newValue
        }
    }

    /// Installs once per process and prepares an alternate signal stack on the calling thread.
    public func prepare() {
        SignalCrashCapture.shared.prepare()
    }

    /// Call from each application-owned worker thread requiring stack-overflow coverage.
    /// Alternate stacks are thread-local and cannot be installed on another thread's behalf.
    /// GCD/system/third-party threads without a prepared stack have no guaranteed
    /// stack-overflow coverage; their ordinary fatal signals may still be captured.
    public static func prepareCurrentThread() {
        SignalCrashCapture.prepareCurrentThread()
    }
}

/// Process-wide capture configuration. Construction does not replace callbacks;
/// the last explicitly assigned instance/static callback takes precedence.
public class CrashHandler: @unchecked Sendable {
    /// NSExceptions are delivered immediately; signal crashes are delivered on the next launch.
    /// Register before prepare()/DebugSwift.setup(); late signal observers are not replayed.
    public var exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)? {
        get { CrashSignalExceptionHandler.exceptionReceiveClosure }
        set {
            CrashSignalExceptionHandler.exceptionReceiveClosure = newValue
            CrashUncaughtExceptionHandler.exceptionReceiveClosure = newValue.map { callback in
                { signal, exception, info, _ in callback(signal, exception, info) }
            }
        }
    }

    static let shared = CrashHandler()

    let uncaughtExceptionHandler: CrashUncaughtExceptionHandler
    let signalExceptionHandler: CrashSignalExceptionHandler

    public init() {
        self.uncaughtExceptionHandler = CrashUncaughtExceptionHandler()
        self.signalExceptionHandler = CrashSignalExceptionHandler()
    }

    public func prepare() {
        uncaughtExceptionHandler.prepare()
        signalExceptionHandler.prepare()
    }
}
