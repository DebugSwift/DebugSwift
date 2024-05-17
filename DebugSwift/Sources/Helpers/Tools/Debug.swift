//
//  Debug.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

enum Debug {
    @UserDefaultAccess(key: .debugger, defaultValue: true)
    static var enable: Bool

    static func execute(action: () -> Void) {
        guard enable else { return }
        action()
    }

    static func print(
        _ message: Any...
    ) {
        guard enable else { return }
        Swift.print("[DebugSwift] 🚀 → \(message)")
    }
}
