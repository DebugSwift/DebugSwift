//
//  Thread+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 26/04/24.
//

import Foundation

public extension Thread {
    /**
     An array of string containing parsed class names and method names
     */
    class func simpleCallStackSymbols(
        _ stack: [String] = Thread.callStackSymbols
    ) -> [String] {
        let symbols: [String] = Thread.callStackSymbols
            .dropFirst()
            .map {
                guard
                    let module: String = $0.replacingOccurrences(
                        of: "\\s+",
                        with: " ",
                        options: .regularExpression,
                        range: nil
                    ).components(
                        separatedBy: " "
                    )[safe: 1],
                    !module.hasPrefix("DebugSwift")
                else {
                    return ""
                }
                if let symbol: (
                    String,
                    String
                ) = CallStackParser.classAndMethodForStackSymbol(
                    $0
                ) {
                    return "\(symbol.0) \(symbol.1)"
                }
                if let closure = CallStackParser.closureForStackSymbol(
                    $0
                ) {
                    return closure
                }
                return ""
            }
            .filter {
                !$0.isEmpty
            }

        let count: Int = symbols.count
        let digit: Int = String(
            count
        ).count

        return symbols
            .reversed()
            .enumerated()
            .map {
                let index: String = String(
                    $0.0 + 1
                ).leftPadding(
                    toLength: digit,
                    withPad: "0"
                )
                let head: String = "[CallStack:\(index)/\(count)]"
                return "\(head) \($0.1)"
            }
            .reversed()
    }

    /**
     A formatted string containing parsed class names and method names
     */
    class var simpleCallStackString: String {
        return simpleCallStackSymbols().joined(
            separator: "\n"
        )
    }
}
