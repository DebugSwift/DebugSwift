//
//  FeatureBaseTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 27/12/2024.
//

import XCTest
@testable import DebugSwift

class FeatureBaseTests: XCTestCase {

    func testDebugSwiftFeature_allCases() {
        // Given
        let expectedCases: [DebugSwiftFeature] = [.network, .performance, .interface, .resources, .app]

        // When
        let allCases = DebugSwiftFeature.allCases

        // Then
        XCTAssertEqual(allCases, expectedCases, "DebugSwiftFeature.allCases should return all defined cases")
    }

    func testDebugSwiftSwizzleFeature_allCases() {
        // Given
        let expectedCases: [DebugSwiftSwizzleFeature] = [.network, .webSocket, .location, .views, .crashManager, .leaksDetector, .console, .pushNotifications, .swiftUIRender]

        // When
        let allCases = DebugSwiftSwizzleFeature.allCases

        // Then
        XCTAssertEqual(allCases, expectedCases, "DebugSwiftSwizzleFeature.allCases should return all defined cases")
    }

    func testDebugSwiftBetaFeature_allCases() {
        // Given
        let expectedCases: [DebugSwiftBetaFeature] = [.swiftUIRenderTracking]

        // When
        let allCases = DebugSwiftBetaFeature.allCases

        // Then
        XCTAssertEqual(allCases, expectedCases, "DebugSwiftBetaFeature.allCases should return all defined cases")
    }

    func testDebugSwiftFeatures_deprecated() {
        // Given
        let expectedType: DebugSwiftFeature.Type = DebugSwiftFeature.self

        // When
        let aliasType: DebugSwiftFeatures.Type = DebugSwiftFeatures.self

        // Then
        XCTAssertTrue(aliasType == expectedType, "DebugSwiftFeatures should be an alias for DebugSwiftFeature")
    }
}
