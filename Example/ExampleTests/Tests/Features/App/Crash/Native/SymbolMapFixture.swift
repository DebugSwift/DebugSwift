//
//  SymbolMapFixture.swift
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

// Host-only executable built by Scripts/test_symbol_map.sh.
@inline(never)
private func debugSwiftSymbolMapFixture(_ value: Int) -> Int {
    value + 1
}

print(debugSwiftSymbolMapFixture(41))
