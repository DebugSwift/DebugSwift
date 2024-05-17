//
//  Performance.MemoryWarning.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/05/24.
//

import UIKit

enum PerformanceMemoryWarning {
    static var i = 1

    static func generate() {
        UIApplication.shared.perform(Selector(("_performMemoryWarning")))

        for _ in 0...1200 * i {
            var p: [UnsafeMutableRawPointer] = []
            var allocatedMB = 0
            p.append(malloc(1048576))
            memset(p[allocatedMB], 0, 1048576)
            allocatedMB += 1
        }

        i += 1
    }
}
