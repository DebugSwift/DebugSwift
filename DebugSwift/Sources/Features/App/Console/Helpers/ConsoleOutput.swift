//
//  ConsoleOutput.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/05/24.
//

import Foundation

enum ConsoleOutput {
    static var printAndNSLogOutput = [String]()
    static var errorOutput = [String]()

    static func removeAll() {
        printAndNSLogOutput.removeAll()
    }

    static func printAndNSLogOutputFormatted() -> String {
        printAndNSLogOutput.clean()
    }

    static func errorOutputFormatted() -> String {
        errorOutput.clean()
    }
}

extension [String] {
    fileprivate func clean() -> String {
        filter { !$0.contains("[DebugSwift] 🚀") }.reversed().joined(separator: "\n\n")
    }
}
