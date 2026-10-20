//
//  SymbolicatorAdapter.swift
//  DebugSwift
//
//  Created by Matheus Gois (Crash Symbolication) on 16/07/26.
//

import Foundation

// MARK: - Crash Symbolication — runtime adapter

/// Loads a build-time symbol map and resolves native frames only after matching
/// the original image UUID and normalizing its runtime address.
final class SymbolicatorAdapter: @unchecked Sendable {

    static let shared = SymbolicatorAdapter()

    private var symbolTable: SymbolTable?

    /// Whether a symbol table has been loaded and is available for resolution.
    var isSymbolTableLoaded: Bool { symbolTable != nil }

    private init() {
    }

    /// Load a symbol map from a JSON file path. No-op if the file is absent.
    @discardableResult
    func load(from path: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = String(data: data, encoding: .utf8),
              let table = SymbolTable.parse(json: json)
        else { return false }
        symbolTable = table
        return true
    }

    /// Resolve a single raw frame address to a symbol.
    func symbolicate(address: UInt64) -> Symbol? {
        symbolTable.flatMap { $0.symbolicate(frames: [address]).first?.symbol }
    }

    /// Resolve image-associated native addresses, preserving unknown and plain-text frames.
    func symbolicate(traces: [CrashModel.Trace]) -> [String] {
        guard let table = symbolTable else {
            return traces.map(\.title)
        }
        return traces.map { trace in
            // Signal frames must carry their original image identity. Never apply a symbol
            // map for the current build to an absolute address from another process/build.
            guard let address = trace.address,
                  let image = trace.image,
                  table.imageUUID == image.uuid,
                  let normalized = image.normalizedAddress(for: address)
            else { return trace.title }
            if let symbol = table.symbolicate(frames: [normalized]).first?.symbol {
                guard !symbol.file.isEmpty, symbol.line > 0 else { return symbol.name }
                return "\(symbol.name)  \(symbol.file):\(symbol.line)"
            }
            return trace.title
        }
    }
}
