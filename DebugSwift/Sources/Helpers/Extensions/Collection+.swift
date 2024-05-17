//
//  Collection+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 26/04/24.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
