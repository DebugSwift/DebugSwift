//
//  SymbolicatorAdapter.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation

// MARK: - #20 Crash Symbolication — runtime adapter

/// Loads a symbol map JSON (produced by `Scripts/generate_symbol_map.sh` at
/// build time) and resolves `CrashModel.Trace` titles to `(symbol, file, line)`
/// using the pure `SymbolTable`.
enum SymbolicatorAdapter {

    /// The loaded symbol table, or `nil` if no map is present.
    static var shared: SymbolTable?

    /// Load a symbol map from a JSON file path. No-op if the file is absent.
    @discardableResult
    static func load(from path: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = String(data: data, encoding: .utf8),
              let table = SymbolTable.parse(json: json)
        else { return false }
        shared = table
        return true
    }

    /// Resolve a single raw frame address to a symbol.
    static func symbolicate(address: UInt64) -> Symbol? {
        shared.flatMap { $0.symbolicate(frames: [address]).first?.symbol }
    }

    /// Resolve a list of `CrashModel.Trace` titles (raw frame strings) to
    /// pretty-printable symbol descriptions.
    static func symbolicate(traces: [CrashModel.Trace]) -> [String] {
        let addresses = traces.compactMap { parse(address: $0.title) }
        guard let table = shared else {
            return traces.map(\.title)
        }
        let resolved = table.symbolicate(frames: addresses)
        return zip(traces, resolved).map { trace, result in
            if let symbol = result.symbol {
                return "\(symbol.name)  \(symbol.file):\(symbol.line)"
            }
            return trace.title
        }
    }

    // MARK: - Private

    /// Parse a hex or decimal address from a frame string like
    /// `0x1024abc  Foo + 42` or a bare `0x1024abc`.
    private static func parse(address string: String) -> UInt64? {
        let trimmed = string.split(separator: " ").first.map(String.init) ?? string
        if trimmed.hasPrefix("0x") {
            return UInt64(trimmed.dropFirst(2), radix: 16)
        }
        return UInt64(trimmed)
    }
}
