//
//  FeedbackInpact.swift
//  DebugSwift
//
//  Created by Matheus Gois on 12/03/24.
//

import Foundation

enum ImpactFeedback {
    @UserDefaultAccess(key: .feedback, defaultValue: true)
    static var enable: Bool

    static func generate(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard enable else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
