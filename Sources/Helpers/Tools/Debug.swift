//
//  Debug.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

enum Debug {
    enum DebugLevel {
        case full
        case normal
        case minimal
    }

    static func execute(level: DebugLevel, action: () -> Void) {
        switch level {
        case .full:
            // Execute the action for full debugging
            action()
        case .normal:
            // Execute the action for normal debugging
            // You can customize this behavior based on your needs
            action()
        case .minimal:
            // Execute the action for minimal debugging
            // You can customize this behavior based on your needs
            action()
        }
    }

    static func print(
        _ message: String,
        level: DebugLevel = .normal
    ) {
        switch level {
        case .full, .normal:
            // Print the message for full and normal levels
            Swift.print(message)
        case .minimal:
            // Do nothing for minimal level
            break
        }
    }
}
