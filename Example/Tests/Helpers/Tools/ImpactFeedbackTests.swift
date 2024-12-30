//
//  ImpactFeedbackTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 21/12/2024.
//

import XCTest
@testable import DebugSwift

final class ImpactFeedbackTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ImpactFeedback.enable = true
    }

    override func tearDown() {
        ImpactFeedback.enable = true
        super.tearDown()
    }

    func testGenerateFeedbackWhenEnabled() {
        // Given
        ImpactFeedback.enable = true
        let feedbackGenerator = MockUIImpactFeedbackGenerator()

        // When
        ImpactFeedback.generate(feedbackGenerator)

        // Then
        XCTAssertTrue(feedbackGenerator.impactOccurredCalled, "Feedback should be generated when enabled")
    }

    func testGenerateFeedbackWhenDisabled() {
        // Given
        ImpactFeedback.enable = false
        let feedbackGenerator = MockUIImpactFeedbackGenerator()

        // When
        ImpactFeedback.generate(feedbackGenerator)

        // Then
        XCTAssertFalse(feedbackGenerator.impactOccurredCalled, "Feedback should not be generated when disabled")
    }
}

// Mock class for UIImpactFeedbackGenerator
class MockUIImpactFeedbackGenerator: UIImpactFeedbackGenerator {
    var impactOccurredCalled = false

    override func impactOccurred() {
        impactOccurredCalled = true
    }
}
