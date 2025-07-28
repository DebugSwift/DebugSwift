//
//  DebugSwiftSwiftUIRenderTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 28/01/2025.
//

import XCTest
@testable import DebugSwift

final class DebugSwiftSwiftUIRenderTests: XCTestCase {
    
    @MainActor
    override func setUp() {
        super.setUp()
        // Reset to default state
        UIView.disableSwiftUIRenderTracking()
        UIView.setPersistentOverlays(false)
        UIView.setOverlayDuration(1.0)
        UIView.setLoggingEnabled(true)
        UIView.setOverlayStyle(.borderWithCount)
        UIView.clearSwiftUIRenderStats()
        UIView.clearAllPersistentOverlays()
    }
    
    @MainActor
    override func tearDown() {
        // Clean up after tests
        UIView.disableSwiftUIRenderTracking()
        UIView.clearSwiftUIRenderStats()
        UIView.clearAllPersistentOverlays()
        super.tearDown()
    }
    
    // MARK: - Enable/Disable Tests
    
    func testIsEnabledDefault() {
        // Given & When
        let isEnabled = UIView.isSwiftUIRenderTrackingEnabled
        
        // Then
        XCTAssertFalse(isEnabled, "Should be disabled by default")
    }
    
    func testEnableSwiftUIRenderTracking() {
        // Given
        XCTAssertFalse(UIView.isSwiftUIRenderTrackingEnabled)
        
        // When
        UIView.enableSwiftUIRenderTracking()
        
        // Then
        XCTAssertTrue(UIView.isSwiftUIRenderTrackingEnabled)
    }
    
    func testDisableSwiftUIRenderTracking() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        XCTAssertTrue(UIView.isSwiftUIRenderTrackingEnabled)
        
        // When
        UIView.disableSwiftUIRenderTracking()
        
        // Then
        XCTAssertFalse(UIView.isSwiftUIRenderTrackingEnabled)
    }
    
    // MARK: - Persistent Overlays Tests
    
    func testPersistentOverlaysDefault() {
        // Given & When
        let persistentOverlays = UIView.isPersistentOverlaysEnabled
        
        // Then
        XCTAssertFalse(persistentOverlays, "Persistent overlays should be disabled by default")
    }
    
    func testSetPersistentOverlays() {
        // Given
        XCTAssertFalse(UIView.isPersistentOverlaysEnabled)
        
        // When
        UIView.setPersistentOverlays(true)
        
        // Then
        XCTAssertTrue(UIView.isPersistentOverlaysEnabled)
        
        // When
        UIView.setPersistentOverlays(false)
        
        // Then
        XCTAssertFalse(UIView.isPersistentOverlaysEnabled)
    }
    
    // MARK: - Overlay Duration Tests
    
    func testOverlayDurationDefault() {
        // Given & When
        let duration = UIView.getOverlayDuration
        
        // Then
        XCTAssertEqual(duration, 1.0, accuracy: 0.001, "Default overlay duration should be 1.0 seconds")
    }
    
    func testSetOverlayDuration() {
        // Given
        let testDuration: TimeInterval = 2.5
        
        // When
        UIView.setOverlayDuration(testDuration)
        
        // Then
        XCTAssertEqual(UIView.getOverlayDuration, testDuration, accuracy: 0.001)
    }
    
    func testOverlayDurationEdgeCases() {
        // Test with zero
        UIView.setOverlayDuration(0.0)
        XCTAssertEqual(UIView.getOverlayDuration, 0.0, accuracy: 0.001)
        
        // Test with negative value
        UIView.setOverlayDuration(-1.0)
        XCTAssertEqual(UIView.getOverlayDuration, -1.0, accuracy: 0.001)
        
        // Test with large value
        UIView.setOverlayDuration(999.0)
        XCTAssertEqual(UIView.getOverlayDuration, 999.0, accuracy: 0.001)
    }
    
    // MARK: - Logging Tests
    
    func testLoggingEnabledDefault() {
        // Given & When
        let loggingEnabled = UIView.isLoggingEnabled
        
        // Then
        XCTAssertTrue(loggingEnabled, "Logging should be enabled by default")
    }
    
    func testSetLoggingEnabled() {
        // Given
        XCTAssertTrue(UIView.isLoggingEnabled)
        
        // When
        UIView.setLoggingEnabled(false)
        
        // Then
        XCTAssertFalse(UIView.isLoggingEnabled)
        
        // When
        UIView.setLoggingEnabled(true)
        
        // Then
        XCTAssertTrue(UIView.isLoggingEnabled)
    }
    
    // MARK: - Overlay Style Tests
    
    func testOverlayStyleDefault() {
        // Given & When
        let overlayStyle = UIView.getOverlayStyle
        
        // Then
        XCTAssertEqual(overlayStyle, .borderWithCount, "Default overlay style should be borderWithCount")
    }
    
    func testSetOverlayStyle() {
        // Test all overlay styles
        let styles: [UIView.OverlayStyle] = [.border, .borderWithCount, .none]
        
        for style in styles {
            // When
            UIView.setOverlayStyle(style)
            
            // Then
            XCTAssertEqual(UIView.getOverlayStyle, style)
        }
    }
    
    // MARK: - Statistics Tests
    
    func testClearStats() {
        // Given & When & Then - should not crash
        UIView.clearSwiftUIRenderStats()
    }
    
    // MARK: - Persistent Overlays Management Tests
    
    @MainActor
    func testClearPersistentOverlays() {
        // Given & When & Then - should not crash
        UIView.clearAllPersistentOverlays()
    }
    
    // MARK: - Integration Tests
    
    func testAllSettingsTogether() {
        // Test that all settings can be configured together without conflicts
        
        // When
        UIView.enableSwiftUIRenderTracking()
        UIView.setPersistentOverlays(true)
        UIView.setOverlayDuration(3.0)
        UIView.setLoggingEnabled(false)
        UIView.setOverlayStyle(.border)
        
        // Then
        XCTAssertTrue(UIView.isSwiftUIRenderTrackingEnabled)
        XCTAssertTrue(UIView.isPersistentOverlaysEnabled)
        XCTAssertEqual(UIView.getOverlayDuration, 3.0, accuracy: 0.001)
        XCTAssertFalse(UIView.isLoggingEnabled)
        XCTAssertEqual(UIView.getOverlayStyle, .border)
    }
    
    func testStateConsistency() {
        // Test that enabling/disabling doesn't affect other settings
        
        // Given
        UIView.setPersistentOverlays(true)
        UIView.setOverlayDuration(2.0)
        UIView.setLoggingEnabled(false)
        UIView.setOverlayStyle(.none)
        
        // When
        UIView.enableSwiftUIRenderTracking()
        UIView.disableSwiftUIRenderTracking()
        
        // Then - other settings should remain unchanged (except persistent overlays is cleared when disabled)
        XCTAssertFalse(UIView.isPersistentOverlaysEnabled) // This gets cleared when disabling
        XCTAssertEqual(UIView.getOverlayDuration, 2.0, accuracy: 0.001)
        XCTAssertFalse(UIView.isLoggingEnabled)
        XCTAssertEqual(UIView.getOverlayStyle, .none)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() {
        // Test that UIView static methods can be accessed from multiple threads
        let expectation = self.expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            DispatchQueue.global().async {
                if i % 2 == 0 {
                    UIView.enableSwiftUIRenderTracking()
                } else {
                    UIView.disableSwiftUIRenderTracking()
                }
                UIView.setOverlayDuration(Double(i))
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Concurrent access should complete without errors")
        }
    }
} 