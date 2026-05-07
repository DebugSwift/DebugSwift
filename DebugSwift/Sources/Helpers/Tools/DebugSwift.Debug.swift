//
//  Debug.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

enum Debug {
    private static let enableKey = "debugger"
    private static let defaultValue = false
    
    nonisolated(unsafe) static var enable: Bool {
        get {
            UserDefaults.standard.object(forKey: enableKey) as? Bool ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enableKey)
        }
    }

    static func execute(action: () -> Void) {
        #if DEBUG
        guard enable else { return }
        action()
        #endif
    }

    static func print(
        _ message: Any...
    ) {
        guard enable else { return }
//        Swift.print("[DebugSwift] 🚀 → \(message)")
    }
}
