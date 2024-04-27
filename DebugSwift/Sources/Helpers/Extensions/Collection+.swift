//
//  Collection+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 26/04/24.
//

import Foundation

internal extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
