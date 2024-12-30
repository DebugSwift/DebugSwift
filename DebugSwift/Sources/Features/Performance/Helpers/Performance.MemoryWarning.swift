//
//  Performance.MemoryWarning.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/05/24.
//

import UIKit

enum PerformanceMemoryWarning {
    static func generate() {
        UIApplication.shared.perform(Selector(("_performMemoryWarning")))

        for _ in 0...1200 {
            var p: [UnsafeMutableRawPointer] = []
            var allocatedMB = 0
            p.append(malloc(1_048_576))
            memset(p[allocatedMB], 0, 1_048_576)
            allocatedMB += 1
        }
    }
}
