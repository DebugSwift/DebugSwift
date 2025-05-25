//
//  ImpactFeedbackTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 21/12/2024.
//

import Testing
import UIKit
@testable import DebugSwift

struct ImpactFeedbackTests {

    init() {
        ImpactFeedback.enable = true
    }

    @Test("Generate feedback when enabled")
    @MainActor
    func generateFeedbackWhenEnabled() async {
        // Given
        ImpactFeedback.enable = true
        let feedbackGenerator = MockUIImpactFeedbackGenerator()

        // When
        ImpactFeedback.generate(feedbackGenerator)
        
        // Then
        #expect(feedbackGenerator.impactOccurredCalled == true)
    }

    @Test("Don't generate feedback when disabled")
    @MainActor
    func generateFeedbackWhenDisabled() async {
        // Given
        ImpactFeedback.enable = false
        let feedbackGenerator = MockUIImpactFeedbackGenerator()

        // When
        ImpactFeedback.generate(feedbackGenerator)
        
        // Then
        #expect(feedbackGenerator.impactOccurredCalled == false)
    }
}

// Mock class for UIImpactFeedbackGenerator
class MockUIImpactFeedbackGenerator: UIImpactFeedbackGenerator {
    var impactOccurredCalled = false

    override func impactOccurred() {
        impactOccurredCalled = true
    }
}
