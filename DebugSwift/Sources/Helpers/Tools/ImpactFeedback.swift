//
//  ImpactFeedback.swift
//  DebugSwift
//
//  Created by Matheus Gois on 12/03/24.
//

import UIKit

enum ImpactFeedback {
    private static let enableKey = "feedback"
    private static let defaultValue = true
    
    nonisolated(unsafe) static var enable: Bool {
        get {
            UserDefaults.standard.object(forKey: enableKey) as? Bool ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enableKey)
        }
    }

    @MainActor
    static func generate(_ feedback: UIImpactFeedbackGenerator? = nil) {
        guard enable else { return }
        let generator = feedback ?? UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
