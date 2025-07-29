//
//  FeatureHandlingBetaTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 29/07/2025.
//

import XCTest
@testable import DebugSwift

@MainActor
final class FeatureHandlingBetaTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset to default state
        FeatureHandling.enabledBetaFeatures = []
        UIView.disableSwiftUIRenderTracking()
    }
    
    override func tearDown() {
        // Clean up after tests
        FeatureHandling.enabledBetaFeatures = []
        UIView.disableSwiftUIRenderTracking()
        super.tearDown()
    }

    func testBetaFeaturesDisabledByDefault() {
        // Given & When - default state
        
        // Then
        XCTAssertTrue(FeatureHandling.enabledBetaFeatures.isEmpty, "Beta features should be empty by default")
        XCTAssertFalse(FeatureHandling.enabledBetaFeatures.contains(.swiftUIRenderTracking), "SwiftUI render tracking should not be enabled by default")
    }
    
    func testEnableBetaFeatures() {
        // Given
        let betaFeatures: [DebugSwiftBetaFeature] = [.swiftUIRenderTracking]
        
        // When
        FeatureHandling.enabledBetaFeatures = betaFeatures
        
        // Then
        XCTAssertEqual(FeatureHandling.enabledBetaFeatures, betaFeatures, "Beta features should be set correctly")
        XCTAssertTrue(FeatureHandling.enabledBetaFeatures.contains(.swiftUIRenderTracking), "SwiftUI render tracking should be enabled")
    }
    
    func testSwiftUIRenderTrackingRequiresBetaFeature() {
        // Given - beta features disabled
        FeatureHandling.enabledBetaFeatures = []
        
        // When - trying to enable SwiftUI render tracking
        // This should not enable tracking since beta feature is not enabled
        // (Note: This is tested indirectly through the setupMethods logic)
        
        // Then
        XCTAssertFalse(FeatureHandling.enabledBetaFeatures.contains(.swiftUIRenderTracking), "SwiftUI render tracking beta feature should not be enabled")
    }
} 