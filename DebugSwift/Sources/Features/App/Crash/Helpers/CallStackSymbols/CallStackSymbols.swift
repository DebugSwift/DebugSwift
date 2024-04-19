//
//  CallStackSymbols.swift
//
//
//  Created by Naruki Chigira on 2021/07/23.
//

import Foundation

/// Get current call stack as dladdr array representaion.
public func current() throws -> [DLADDR] {
    let parser = DLADDRParser()
    let callStackSymbols: [String] = Thread.callStackSymbols
    return try callStackSymbols.map { row in
        try parser.parse(input: row)
    }
}

