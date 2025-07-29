//
//  ConsoleOutput.shared.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/05/24.
//

import Foundation

class ConsoleOutput: @unchecked Sendable {
    
    static let shared = ConsoleOutput()
    
    private init() {}

    private let lock = NSLock()
    private var printAndNSLogOutput = [String]()
    private var errorOutput = [String]()

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        printAndNSLogOutput.removeAll()
    }

    func printAndNSLogOutputFormatted() -> String {
        lock.lock()
        defer { lock.unlock() }
        return printAndNSLogOutput.clean()
    }
    
    func addPrintAndNSLogOutput(_ output: String) {
        lock.lock()
        defer { lock.unlock() }
        printAndNSLogOutput.append(output)
    }
    
    func addErrorOutput(_ output: String) {
        lock.lock()
        defer { lock.unlock() }
        errorOutput.append(output)
    }
    
    func getPrintAndNSLogOutput() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return printAndNSLogOutput
    }
    
    func getErrorOutput() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return errorOutput
    }

    func errorOutputFormatted() -> String {
        lock.lock()
        defer { lock.unlock() }
        return errorOutput.clean()
    }

    func removeAllPrintAndNSLogOutput(_ info: String) {
        lock.lock()
        defer { lock.unlock() }
        printAndNSLogOutput.removeAll(where: { $0 == info })
    }
    
    func removePrintAndNSLogOutput(at index: Int) {
        lock.lock()
        defer { lock.unlock() }
        printAndNSLogOutput.remove(at: index)
    }
        
}

extension [String] {
    fileprivate func clean() -> String {
        filter { !$0.contains("[DebugSwift] 🚀") }.reversed().joined(separator: "\n\n")
    }
}
