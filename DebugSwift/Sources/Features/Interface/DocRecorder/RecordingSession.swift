//
//  RecordingSession.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Combine
import Foundation
import UIKit

@MainActor
final class RecordingSession: ObservableObject {
    struct Step {
        let index: Int
        let screenshot: UIImage
        let annotatedImage: UIImage
        let interactionType: InteractionType
        let location: CGPoint
        let timestamp: Date
    }

    enum InteractionType {
        case tap(viewDescription: String)
        case scroll(direction: ScrollDirection)
        case textInput(fieldDescription: String)
    }

    enum ScrollDirection {
        case up
        case down
        case left
        case right

        var arrowDirection: ScrollDirection {
            switch self {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
            }
        }
    }

    @Published var steps: [Step] = []
    @Published var isPaused: Bool = false
    var stepCounter: Int = 0

    func addStep(_ step: Step) {
        guard !isPaused else { return }
        steps.append(step)
        stepCounter += 1
    }

    func clear() {
        steps.removeAll()
        stepCounter = 0
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }
}
