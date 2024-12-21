//
//  ImpactFeedback.swift
//  DebugSwift
//
//  Created by Matheus Gois on 12/03/24.
//

import UIKit

enum ImpactFeedback {
    @UserDefaultAccess(key: .feedback, defaultValue: true)
    static var enable: Bool

    static func generate(_ feedback: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)) {
        guard enable else { return }
        feedback.impactOccurred()
    }
}
