//
//  SymbolTable.swift
//  DebugSwift
//
//  Created by Matheus Gois (Crash Symbolication) on 16/07/26.
//

import Foundation

// MARK: - Crash Symbolication

/// A resolved symbol for a code address.
public struct Symbol: Equatable {
    public let name: String
    public let file: String
    public let line: Int

    public init(name: String, file: String, line: Int) {
        self.name = name
        self.file = file
        self.line = line
    }
}

/// A sorted table of `(address, symbol)` entries used to resolve raw frame
/// addresses via the standard symbolication rule: the closest preceding
/// symbol whose address ≤ the frame.
public struct SymbolTable {

    public struct Entry {
        public let address: UInt64
        public let symbol: Symbol

        public init(address: UInt64, symbol: Symbol) {
            self.address = address
            self.symbol = symbol
        }
    }

    public let loadAddress: UInt64
    public let entries: [Entry]

    public init(loadAddress: UInt64, entries: [Entry]) {
        self.loadAddress = loadAddress
        self.entries = entries
    }

    /// Resolve a set of raw frame addresses to symbols. Frames outside the
    /// table (no preceding entry) return `nil`.
    public func symbolicate(frames: [UInt64]) -> [(address: UInt64, symbol: Symbol?)] {
        let sorted = entries.sorted { $0.address < $1.address }
        return frames.map { frame in
            (frame, sorted.last { $0.address <= frame }?.symbol)
        }
    }

    /// Reconstruct a `SymbolTable` from a JSON string (the build-phase script
    /// output). Returns `nil` if the JSON is malformed.
    public static func parse(json: String) -> SymbolTable? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        let load = UInt64(object["loadAddress"] as? Int ?? 0)
        let array = object["symbols"] as? [[String: Any]] ?? []
        let parsed: [Entry] = array.compactMap { entry in
            guard let rawAddress = entry["address"] as? Int,
                  let address = UInt64(exactly: rawAddress),
                  let name = entry["name"] as? String
            else { return nil }
            let file = entry["file"] as? String ?? ""
            let line = entry["line"] as? Int ?? 0
            return Entry(address: address, symbol: Symbol(name: name, file: file, line: line))
        }
        return SymbolTable(loadAddress: load, entries: parsed)
    }
}
