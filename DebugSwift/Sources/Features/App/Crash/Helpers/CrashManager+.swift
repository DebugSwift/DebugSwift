//
//  CrashManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation
import UIKit
import MachO

/// Type of crash
enum CrashType: String, Codable {
    case nsexception
    case signal

    var fileName: String { "\(rawValue)_crashes.json" }
}

func unSetUncaughtException() {
    NSSetUncaughtExceptionHandler(nil)
}

func registerSignalHandler() {
    unregisterSignalHandler()

    signal(SIGABRT, signalHandler)
    signal(SIGSEGV, signalHandler)
    signal(SIGBUS, signalHandler)
    signal(SIGTRAP, signalHandler)
    signal(SIGILL, signalHandler)
}

func registerSignalExperimentalHandler() {
    unregisterSignalExperimentalHandler()

    signal(SIGHUP, signalHandler)
    signal(SIGINT, signalHandler)
    signal(SIGQUIT, signalHandler)
    signal(SIGFPE, signalHandler)
    signal(SIGPIPE, signalHandler)
}

func unregisterSignalHandler() {
    signal(SIGINT, SIG_DFL)
    signal(SIGSEGV, SIG_DFL)
    signal(SIGTRAP, SIG_DFL)
    signal(SIGABRT, SIG_DFL)
    signal(SIGILL, SIG_DFL)
}

func unregisterSignalExperimentalHandler() {
    signal(SIGHUP, SIG_DFL)
    signal(SIGINT, SIG_DFL)
    signal(SIGQUIT, SIG_DFL)
    signal(SIGFPE, SIG_DFL)
    signal(SIGPIPE, SIG_DFL)
}

func nsExceptionHandler(exception: NSException) {
    let arr = exception.callStackSymbols
    let reason = exception.reason ?? "No reason provided"
    let name = exception.name.rawValue
    let userInfo = exception.userInfo ?? [:]

    var crash = "NSException Crash:\n"
    crash += "Name: \(name)\n"
    crash += "Reason: \(String(describing: reason))"

    crash += "User Info:\n"
    if !userInfo.isEmpty {
        for (key, value) in userInfo {
            crash += "\(key): \(value)\n"
        }
    }

    let trace = CrashModel(
        type: .nsexception,
        details: .builder(name: crash),
        context: .builder(),
        traces: .builder()
    )
    CrashManager.save(crash: trace)
}

func signalHandler(signal: Int32) {
    let crash = "Signal Crash: \(signal)"

    let trace = CrashModel(
        type: .signal,
        details: .builder(name: crash),
        context: .builder(),
        traces: .builder()
    )
    CrashManager.save(crash: trace)
    exit(signal)
}

func slideAddress() -> Int64 {
    var slide: Int64 = 0
    for imageIndex in 0..<_dyld_image_count() {
        let header = _dyld_get_image_header(imageIndex).pointee
        if header.filetype == MH_EXECUTE {
            slide = Int64(_dyld_get_image_vmaddr_slide(imageIndex))
            break
        }
    }
    return slide
}

func slideAddresses() -> [String: Int64] {
    var slides: [String: Int64] = [:]
    for imageIndex in 0..<_dyld_image_count() {
        if let imageNamePtr = _dyld_get_image_name(imageIndex) {
            let imageName = String(cString: imageNamePtr)
            slides[imageName] = Int64(_dyld_get_image_vmaddr_slide(imageIndex))
        }
    }
    return slides
}

struct Trace {

    static func classNameFromSymbol(_ symbol: String) -> String? {
        // Example symbol: "0x0000000101396bc0 $s10DebugSwift13signalHandler0C0ys5Int32V_tF + 772"

        // Define a regular expression pattern to match the class name
        let pattern = "\\$s(\\S+)\\d+"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: symbol.utf16.count)

            if let match = regex.firstMatch(in: symbol, options: [], range: range) {
                let classNameRange = Range(match.range(at: 1), in: symbol)
                if let className = classNameRange.flatMap({ String(symbol[$0]) }) {
                    return className
                }
            }
        } catch {
            Debug.print("Error creating regex: \(error)")
        }

        return nil
    }

    static func fileInfoFromSymbol(_ symbol: String) -> (file: String, line: Int, function: String)? {
        // Example symbol: "0x0000000101396bc0 $s10DebugSwift13signalHandler0C0ys5Int32V_tF + 772"

        // Define a regular expression pattern to match file name, line number, and function
        let pattern = "\\s+(\\S+\\.swift):(\\d+)\\s+(\\S+\\()"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: symbol.utf16.count)

            if let match = regex.firstMatch(in: symbol, options: [], range: range) {
                let fileRange = Range(match.range(at: 1), in: symbol)
                let lineRange = Range(match.range(at: 2), in: symbol)
                let functionRange = Range(match.range(at: 3), in: symbol)

                if let file = fileRange.flatMap({ String(symbol[$0]) }),
                   let lineString = lineRange.flatMap({ String(symbol[$0]) }),
                   let line = Int(lineString),
                   let function = functionRange.flatMap({ String(symbol[$0]) }) {
                    return (file, line, function)
                }
            }
        } catch {
            Debug.print("Error creating regex: \(error)")
        }

        return nil
    }

    static func binaryInformation() -> String {
        var binaryInfo = ""

        for imageIndex in 0..<_dyld_image_count() {
            if let imageNamePtr = _dyld_get_image_name(imageIndex) {
                let imageName = String(cString: imageNamePtr)
                let slideAddress = slideAddressForImageIndex(imageIndex)
                binaryInfo += "\(String(format: "0x%0x", slideAddress)) - \(imageName):\n"
            }
        }

        return binaryInfo
    }

    static func slideAddressForImageIndex(_ index: UInt32) -> Int64 {
        let header = _dyld_get_image_header(index).pointee
        return Int64(_dyld_get_image_vmaddr_slide(index))
    }

}
