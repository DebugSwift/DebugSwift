//
//  Debug.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

enum Debug {
    public enum DebugLevel {
        case full
        case normal
        case minimal
    }

    static func execute(level: DebugLevel, action: () -> Void) {
        switch level {
        case .full:
            action()
        case .normal:
            action()
        case .minimal:
            break
        }
    }

    static func print(
        _ message: String,
        level: DebugLevel = .normal
    ) {
        switch level {
        case .full, .normal:
            Swift.print(message)
        case .minimal:
            break
        }
    }
}
