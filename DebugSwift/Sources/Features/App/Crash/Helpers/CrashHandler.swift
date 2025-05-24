//
//  CrashHandler.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import Foundation
import MachO.dyld

func calculate() -> Int {
    var slide = 0
    for i in 0..<_dyld_image_count() where _dyld_get_image_header(i).pointee.filetype == MH_EXECUTE {
        slide = _dyld_get_image_vmaddr_slide(i)
    }
    return slide
}

// Encapsulate all global state in a thread-safe singleton
private final class CrashHandlerGlobalState: @unchecked Sendable {
    static let shared = CrashHandlerGlobalState()
    
    private let lock = NSLock()
    
    private var _preUncaughtExceptionHandler: NSUncaughtExceptionHandler?
    private var _previousABRTSignalHandler: SignalHandler?
    private var _previousBUSSignalHandler: SignalHandler?
    private var _previousFPESignalHandler: SignalHandler?
    private var _previousILLSignalHandler: SignalHandler?
    private var _previousPIPESignalHandler: SignalHandler?
    private var _previousSEGVSignalHandler: SignalHandler?
    private var _previousSYSSignalHandler: SignalHandler?
    private var _previousTRAPSignalHandler: SignalHandler?
    
    private init() {}
    
    var preUncaughtExceptionHandler: NSUncaughtExceptionHandler? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _preUncaughtExceptionHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _preUncaughtExceptionHandler = newValue
        }
    }
    
    func setSignalHandler(signal: Int32, handler: SignalHandler?) {
        lock.lock()
        defer { lock.unlock() }
        
        switch signal {
        case SIGABRT: _previousABRTSignalHandler = handler
        case SIGBUS: _previousBUSSignalHandler = handler
        case SIGFPE: _previousFPESignalHandler = handler
        case SIGILL: _previousILLSignalHandler = handler
        case SIGPIPE: _previousPIPESignalHandler = handler
        case SIGSEGV: _previousSEGVSignalHandler = handler
        case SIGSYS: _previousSYSSignalHandler = handler
        case SIGTRAP: _previousTRAPSignalHandler = handler
        default: break
        }
    }
    
    func getSignalHandler(signal: Int32) -> SignalHandler? {
        lock.lock()
        defer { lock.unlock() }
        
        switch signal {
        case SIGABRT: return _previousABRTSignalHandler
        case SIGBUS: return _previousBUSSignalHandler
        case SIGFPE: return _previousFPESignalHandler
        case SIGILL: return _previousILLSignalHandler
        case SIGPIPE: return _previousPIPESignalHandler
        case SIGSEGV: return _previousSEGVSignalHandler
        case SIGSYS: return _previousSYSSignalHandler
        case SIGTRAP: return _previousTRAPSignalHandler
        default: return nil
        }
    }
    
    var preHandlers: [Int32: SignalHandler?] {
        lock.lock()
        defer { lock.unlock() }
        
        return [
            SIGABRT: _previousABRTSignalHandler,
            SIGBUS: _previousBUSSignalHandler,
            SIGFPE: _previousFPESignalHandler,
            SIGILL: _previousILLSignalHandler,
            SIGPIPE: _previousPIPESignalHandler,
            SIGSEGV: _previousSEGVSignalHandler,
            SIGSYS: _previousSYSSignalHandler,
            SIGTRAP: _previousTRAPSignalHandler
        ]
    }
}

public class CrashUncaughtExceptionHandler: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _exceptionReceiveClosure: ((Int32?, NSException?, String, [String]) -> Void)?
    
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
        CrashHandlerGlobalState.shared.preUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler(UncaughtExceptionHandler)
    }
}

func UncaughtExceptionHandler(exception: NSException) {
    let arr = exception.callStackSymbols
    let reason = exception.reason ?? ""
    let name = exception.name.rawValue
    var crash = String()
    crash += "\nName: \(name)\nReason: \(reason)"

    CrashUncaughtExceptionHandler.exceptionReceiveClosure?(nil, exception, crash, arr)
    CrashHandlerGlobalState.shared.preUncaughtExceptionHandler?(exception)
    kill(getpid(), SIGKILL)
}

typealias SignalHandler = (Int32, UnsafeMutablePointer<__siginfo>?, UnsafeMutableRawPointer?) -> Void

public class CrashSignalExceptionHandler: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)?
    
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

    public func prepare() {
        backupOriginalHandler()
        signalNewRegister()
    }

    func backupOriginalHandler() {
        for (signal, _) in CrashHandlerGlobalState.shared.preHandlers {
            var tempHandler: SignalHandler?
            backupSingleHandler(signal: signal, preHandler: &tempHandler)
            CrashHandlerGlobalState.shared.setSignalHandler(signal: signal, handler: tempHandler)
        }
    }

    func backupSingleHandler(signal: Int32, preHandler: inout SignalHandler?) {
        let empty: UnsafeMutablePointer<sigaction>? = nil
        var old_action_abrt = sigaction()
        sigaction(signal, empty, &old_action_abrt)
        if old_action_abrt.__sigaction_u.__sa_sigaction != nil {
            preHandler = old_action_abrt.__sigaction_u.__sa_sigaction
        }
    }

    func signalNewRegister() {
        SignalRegister(signal: SIGABRT)
        SignalRegister(signal: SIGBUS)
        SignalRegister(signal: SIGFPE)
        SignalRegister(signal: SIGILL)
        SignalRegister(signal: SIGPIPE)
        SignalRegister(signal: SIGSEGV)
        SignalRegister(signal: SIGSYS)
        SignalRegister(signal: SIGTRAP)
    }
}

func SignalRegister(signal: Int32) {
    var action = sigaction()
    action.__sigaction_u.__sa_sigaction = CrashSignalHandler
    action.sa_flags = SA_NODEFER | SA_SIGINFO
    sigemptyset(&action.sa_mask)
    let empty: UnsafeMutablePointer<sigaction>? = nil
    sigaction(signal, &action, empty)
}

func CrashSignalHandler(
    signal: Int32,
    info: UnsafeMutablePointer<__siginfo>?,
    context: UnsafeMutableRawPointer?
) {
    let exceptionInfo = """
        Signal \(SignalName(signal))
    """

    CrashSignalExceptionHandler.exceptionReceiveClosure?(signal, nil, exceptionInfo)
    ClearSignalRigister()

    let handler = CrashHandlerGlobalState.shared.getSignalHandler(signal: signal)
    handler?(signal, info, context)
    kill(getpid(), SIGKILL)
}

func SignalName(_ signal: Int32) -> String {
    switch signal {
    case SIGABRT: return "SIGABRT"
    case SIGBUS: return "SIGBUS"
    case SIGFPE: return "SIGFPE"
    case SIGILL: return "SIGILL"
    case SIGPIPE: return "SIGPIPE"
    case SIGSEGV: return "SIGSEGV"
    case SIGSYS: return "SIGSYS"
    case SIGTRAP: return "SIGTRAP"
    default: return "None"
    }
}

func ClearSignalRigister() {
    signal(SIGSEGV, SIG_DFL)
    signal(SIGFPE, SIG_DFL)
    signal(SIGBUS, SIG_DFL)
    signal(SIGTRAP, SIG_DFL)
    signal(SIGABRT, SIG_DFL)
    signal(SIGILL, SIG_DFL)
    signal(SIGPIPE, SIG_DFL)
    signal(SIGSYS, SIG_DFL)
}

public class CrashHandler: @unchecked Sendable {
    public var exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)?

    static let shared = CrashHandler()

    let uncaughtExceptionHandler: CrashUncaughtExceptionHandler
    let signalExceptionHandler: CrashSignalExceptionHandler

    public init() {
        self.uncaughtExceptionHandler = CrashUncaughtExceptionHandler()
        self.signalExceptionHandler = CrashSignalExceptionHandler()

        CrashUncaughtExceptionHandler.exceptionReceiveClosure = { [weak self] signal, exception, info, arr in
            self?.exceptionReceiveClosure?(signal, exception, info)
            let trace = CrashModel(
                type: .nsexception,
                details: .builder(name: info),
                traces: .builder(Thread.simpleCallStackSymbols(arr))
            )
            CrashManager.shared.save(crash: trace)
        }

        CrashSignalExceptionHandler.exceptionReceiveClosure = { [weak self] signal, exception, info in
            self?.exceptionReceiveClosure?(signal, exception, info)
            let trace = CrashModel(
                type: .signal,
                details: .builder(name: info),
                traces: .builder(Thread.simpleCallStackSymbols())
            )
            CrashManager.shared.save(crash: trace)
        }
    }

    public func prepare() {
        uncaughtExceptionHandler.prepare()
        signalExceptionHandler.prepare()
    }
}
