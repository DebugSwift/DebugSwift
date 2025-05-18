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

private var preUncaughtExceptionHandler: NSUncaughtExceptionHandler?

public class CrashUncaughtExceptionHandler {
    public static var exceptionReceiveClosure: ((Int32?, NSException?, String, [String]) -> Void)?

    public func prepare() {
        preUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
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
    preUncaughtExceptionHandler?(exception)
    kill(getpid(), SIGKILL)
}

typealias SignalHandler = (Int32, UnsafeMutablePointer<__siginfo>?, UnsafeMutableRawPointer?) -> Void

private var previousABRTSignalHandler: SignalHandler?
private var previousBUSSignalHandler: SignalHandler?
private var previousFPESignalHandler: SignalHandler?
private var previousILLSignalHandler: SignalHandler?
private var previousPIPESignalHandler: SignalHandler?
private var previousSEGVSignalHandler: SignalHandler?
private var previousSYSSignalHandler: SignalHandler?
private var previousTRAPSignalHandler: SignalHandler?
private let preHandlers = [
    SIGABRT: previousABRTSignalHandler,
    SIGBUS: previousBUSSignalHandler,
    SIGFPE: previousFPESignalHandler,
    SIGILL: previousILLSignalHandler,
    SIGPIPE: previousPIPESignalHandler,
    SIGSEGV: previousSEGVSignalHandler,
    SIGSYS: previousSYSSignalHandler,
    SIGTRAP: previousTRAPSignalHandler
]

public class CrashSignalExceptionHandler {
    public static var exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)?

    public func prepare() {
        backupOriginalHandler()
        signalNewRegister()
    }

    func backupOriginalHandler() {
        for (signal, handler) in preHandlers {
            var tempHandler = handler
            backupSingleHandler(signal: signal, preHandler: &tempHandler)
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

    let handler = preHandlers[signal]
    handler??(signal, info, context)
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

public class CrashHandler {
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
