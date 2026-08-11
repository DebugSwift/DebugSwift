//
//  BacktraceManager.swift
//  DebugSwift
//
//  Programmatic backtrace capture for normal execution (not crash reporting).
//  Addresses issue #162 — Swift 6.2 SE-0419 Backtrace API integration.
//
//  SE-0419's `Runtime` module is unavailable on native iOS (device & simulator)
//  as of Xcode 26.x — it only ships for macOS and Mac Catalyst (`ios-macabi`).
//  Since DebugSwift targets iOS only, we use `Thread.callStackSymbols` as the
//  primary capture path and gate the `Runtime`-based symbolicated path behind
//  `canImport(Runtime)` so it activates automatically when the platform
//  supports it (e.g. macOS/Catalyst).
//

#if canImport(Runtime)
import Runtime
#endif

import Foundation

// MARK: - Public Model

/// A single frame in a captured backtrace.
public struct BacktraceFrame: Sendable, Equatable {
    /// Zero-based position in the stack (0 = deepest / capture call site).
    public let index: Int
    /// Best-effort symbolicated description, e.g.
    /// `DebugSwift.BacktraceManager.capture() + 120`.
    public let symbol: String

    public init(index: Int, symbol: String) {
        self.index = index
        self.symbol = symbol
    }
}

/// A backtrace captured at a specific moment during normal execution.
public struct CapturedBacktrace: Sendable, Equatable {
    /// Unique identifier (UUID string).
    public let id: String
    /// When the backtrace was captured.
    public let timestamp: Date
    /// Optional label provided by the caller for easy identification.
    public let label: String?
    /// Ordered frames (index 0 = deepest).
    public let frames: [BacktraceFrame]

    public init(id: String, timestamp: Date, label: String?, frames: [BacktraceFrame]) {
        self.id = id
        self.timestamp = timestamp
        self.label = label
        self.frames = frames
    }
}

// MARK: - Manager

/// Thread-safe singleton that stores programmatically captured backtraces.
///
/// Use ``DebugSwift.Performance.Backtrace.capture`` (or
/// ``DebugSwift.Performance.Backtrace.capture(label:)``) to record a backtrace
/// during normal execution.  Captures are capped at ``maxCapacity`` to avoid
/// unbounded memory growth.
final class BacktraceManager: @unchecked Sendable {

    // MARK: Singleton

    private init() {}
    static let shared = BacktraceManager()

    // MARK: Configuration

    /// Maximum number of captures retained.  Older captures are dropped.
    let maxCapacity = 100

    // MARK: Callbacks

    /// Called whenever a new backtrace is captured, on the calling thread.
    private var _callback: ((CapturedBacktrace) -> Void)?

    /// Called on the main thread to request a table-view reload (UI hook).
    private var _reloadData: (() -> Void)?

    /// Thread-safe accessor for the capture callback.
    var callback: ((CapturedBacktrace) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _callback }
        set { lock.lock(); defer { lock.unlock() }; _callback = newValue }
    }

    /// Thread-safe accessor for the reload-data hook.
    var reloadData: (() -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _reloadData }
        set { lock.lock(); defer { lock.unlock() }; _reloadData = newValue }
    }

    // MARK: Storage

    private let lock = NSLock()
    private var _backtraces: [CapturedBacktrace] = []

    /// All captured backtraces, newest first.
    var backtraces: [CapturedBacktrace] {
        lock.lock(); defer { lock.unlock() }
        return _backtraces
    }

    /// All captured backtraces, oldest first (insertion order).
    var backtracesOldestFirst: [CapturedBacktrace] {
        lock.lock(); defer { lock.unlock() }
        return _backtraces.reversed()
    }

    // MARK: Capture

    /// Captures the current call stack and stores it.
    ///
    /// - Parameter label: Optional human-readable label for the capture.
    /// - Returns: The captured backtrace.
    @discardableResult
    func capture(label: String? = nil) -> CapturedBacktrace {
        let frames = BacktraceCaptureEngine.captureFrames()
        let backtrace = CapturedBacktrace(
            id: UUID().uuidString,
            timestamp: Date(),
            label: label,
            frames: frames
        )

        lock.lock()
        _backtraces.insert(backtrace, at: 0) // newest first
        if _backtraces.count > maxCapacity {
            _backtraces.removeLast()
        }
        let cb = _callback
        let reload = _reloadData
        lock.unlock()

        // Fire the callback synchronously on the calling thread so callers
        // (and tests) receive it immediately, without ordering issues from
        // queued main-thread blocks.
        cb?(backtrace)
        DispatchQueue.main.async {
            reload?()
            Debug.print("📍 Backtrace captured: \(label ?? "unlabeled") — \(frames.count) frames")
        }

        return backtrace
    }

    // MARK: Mutations

    func clear() {
        lock.lock()
        _backtraces.removeAll()
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.reloadData?()
        }
    }

    func remove(at index: Int) {
        lock.lock()
        guard index >= 0, index < _backtraces.count else {
            lock.unlock()
            return
        }
        _backtraces.remove(at: index)
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.reloadData?()
        }
    }
}

// MARK: - Capture Engine

/// Resolves the best available frame representation for the current platform.
enum BacktraceCaptureEngine {

    /// Captures the current call stack as ``BacktraceFrame``s (index 0 = deepest).
    static func captureFrames() -> [BacktraceFrame] {
        // SE-0419 path — available on macOS/Catalyst when the toolchain ships
        // the `Runtime` module.  Not available on native iOS as of Xcode 26.x.
        #if canImport(Runtime)
        if let symbolicated = try? Backtrace.capture().symbolicated() {
            let frames = symbolicated.frames
                .map { describe($0) }
                .filter { symbol in
                    !symbol.contains("BacktraceCaptureEngine")
                        && !symbol.contains("BacktraceManager")
                        && !symbol.contains("DebugSwift.Performance.Backtrace")
                }
            return frames.enumerated().map { idx, symbol in
                BacktraceFrame(index: idx, symbol: symbol)
            }
        }
        #endif

        // Fallback (iOS): Thread.callStackSymbols
        // Filter out DebugSwift-internal frames (capture engine, manager,
        // public API wrapper) so frame 0 is the user's call site.
        let symbols = Thread.callStackSymbols.filter { symbol in
            !symbol.contains("BacktraceCaptureEngine")
                && !symbol.contains("BacktraceManager")
                && !symbol.contains("DebugSwift.Performance.Backtrace")
        }
        return symbols.enumerated().map { idx, symbol in
            BacktraceFrame(index: idx, symbol: symbol)
        }
    }

    #if canImport(Runtime)
    private static func describe(_ frame: Frame) -> String {
        guard let symbol = frame.symbol else { return "<frame \(frame.captured)>" }
        var parts = [symbol.name]
        if let loc = symbol.sourceLocation {
            parts.append("at \(loc.path):\(loc.line)")
        } else {
            parts.append("in \(symbol.imageName) + \(symbol.offset)")
        }
        return parts.joined(separator: " ")
    }
    #endif
}
