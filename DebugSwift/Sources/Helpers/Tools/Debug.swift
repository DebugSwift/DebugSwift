//
//  Debug.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

public enum Debug {
    static var enable: Bool {
        DebugSwift.Debugger.enable
    }

    static func execute(action: () -> Void) {
        guard enable else { return }
        action()
    }

    static func print(
        _ message: String
    ) {
        guard enable else { return }
        Swift.print("[DebugSwift] 🚀 → \(message)")
    }
}
