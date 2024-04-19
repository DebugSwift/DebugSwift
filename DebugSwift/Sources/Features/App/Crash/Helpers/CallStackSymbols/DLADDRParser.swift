//
//  DLADDRParser.swift
//  
//
//  Created by Naruki Chigira on 2021/07/23.
//

import Foundation

/// Parse call stack symbol string to dladdr.
public class DLADDRParser {
    public init() { }

    /// Parse line of Thread.callStackSymbols to DLADDR.
    ///
    /// `input` follows next format.
    /// ```
    /// // {depth} {fname} {fbase} {sname} + {saddr}
    /// (number with radix 10) (string) (number with radix 16) (string) + (number with radix 10)
    /// ```
    ///
    /// Whitespace after `{depth}` vanish when depth is larger than 1,000.
    public func parse(input: String) throws -> DLADDR {
        var input = input

        // Get depth and remove substring representing depth.
        let depth: Int
        do {
            // Get depth.
            let regularExpression = try NSRegularExpression(pattern: "^[\\d]+")
            guard let match = regularExpression.firstMatch(in: input, range: .init(location: 0, length: input.count)) else {
                throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot find depth.")
            }
            let start = input.index(input.startIndex, offsetBy: match.range.location)
            let end = input.index(start, offsetBy: match.range.length)
            guard let number = Int(input[(start)..<(end)]) else {
                throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot convert depth string to integer.")
            }
            depth = number
            // Remove substring representing depth and trimming whitespaces.
            input = String(input.dropFirst(match.range.length)).trimmingCharacters(in: .whitespaces)
        } catch {
            throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot get depth with error: \(error).")
        }

        // Get fname and remove substring representing fname.
        guard let fname = input.components(separatedBy: .whitespaces).first else {
            throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot get fname.")
        }
        input = String(input.dropFirst(fname.count)).trimmingCharacters(in: .whitespaces)

        // Get fbase and remove substring representing fbase.
        guard let fbaseString = input.components(separatedBy: .whitespaces).first else {
            throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot get fbase.")
        }
        guard fbaseString.hasPrefix("0x") else {
            throw CallStackSymbolsError.failedToParseCallStackSymbol("Invalid fbase format (fbase should be '0x...').")
        }
        guard let fbase = UInt64(fbaseString.dropFirst(2), radix: 16) else {
            throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot convert fbase string to integer.")
        }
        input = String(input.dropFirst(fbaseString.count)).trimmingCharacters(in: .whitespaces)

        // Get saddr and remove substring representing depth.
        let saddr: UInt64
        do {
            // Get saddr.
            let regularExpression = try NSRegularExpression(pattern: "[\\d]+$")
            guard let match = regularExpression.firstMatch(in: input, range: .init(location: 0, length: input.count)) else {
                throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot find saddr.")
            }
            let start = input.index(input.startIndex, offsetBy: match.range.location)
            let end = input.index(start, offsetBy: match.range.length)
            guard let number = UInt64(input[(start)..<(end)]) else {
                throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot convert depth string to integer.")
            }
            saddr = number
            // Remove substring representing saddr and trimming whitespaces.
            input = String(input.dropLast(match.range.length + 3)).trimmingCharacters(in: .whitespaces)
        } catch {
            throw CallStackSymbolsError.failedToParseCallStackSymbol("Cannot create NSRegularExpression instance with error: \(error).")
        }

        // Remaining string is sname.
        let sname = input

        return DLADDR(depth: depth, fname: fname, fbase: fbase, sname: sname, saddr: saddr)
    }
}
