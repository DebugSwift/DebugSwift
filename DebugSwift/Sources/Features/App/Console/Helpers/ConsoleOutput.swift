//
//  ConsoleOutput.shared.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/05/24.
//

import Foundation

class ConsoleOutput {
    
    private init() {}
    static let shared = ConsoleOutput()

    var printAndNSLogOutput = [String]()
    var errorOutput = [String]()

    func removeAll() {
        printAndNSLogOutput.removeAll()
    }

    func printAndNSLogOutputFormatted() -> String {
        printAndNSLogOutput.clean()
    }

    func errorOutputFormatted() -> String {
        errorOutput.clean()
    }
}

extension [String] {
    fileprivate func clean() -> String {
        filter { !$0.contains("[DebugSwift] 🚀") }.reversed().joined(separator: "\n\n")
    }
}
