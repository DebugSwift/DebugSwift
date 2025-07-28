//
//  UIView+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UIViewTests: XCTestCase {

    func testAddTopBorderWithColor() {
        // Given
        let view = UIView()
        let color = UIColor.red
        let thickness: CGFloat = 2.0

        // When
        view.addTopBorderWithColor(color: color, thickness: thickness)

        // Then
        guard let border = view.layer.sublayers?.first else {
            XCTFail("Border layer should be added")
            return
        }
        XCTAssertEqual(border.backgroundColor, color.cgColor, "Border color should match")
        XCTAssertEqual(border.frame.height, thickness, "Border thickness should match")
    }

    func testSwizzleMethods() {
        // Given
        let view = UIView()

        // When
        UIView.swizzleMethods()

        // Then
        XCTAssertNotNil(view, "View should be initialized")
    }
    
    // MARK: - SwiftUI Render Tracking Tests
    
    func testSwiftUIRenderTrackingEnable() {
        // Given
        UIView.disableSwiftUIRenderTracking()
        XCTAssertFalse(UIView.isSwiftUIRenderTrackingEnabled)
        
        // When
        UIView.enableSwiftUIRenderTracking()
        
        // Then
        XCTAssertTrue(UIView.isSwiftUIRenderTrackingEnabled)
        
        // Cleanup
        UIView.disableSwiftUIRenderTracking()
    }
    
    func testSwiftUIRenderTrackingDisable() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        XCTAssertTrue(UIView.isSwiftUIRenderTrackingEnabled)
        
        // When
        UIView.disableSwiftUIRenderTracking()
        
        // Then
        XCTAssertFalse(UIView.isSwiftUIRenderTrackingEnabled)
    }
    
    func testSwiftUIRenderPersistentOverlays() {
        // Given
        XCTAssertFalse(UIView.isPersistentOverlaysEnabled)
        
        // When
        UIView.setPersistentOverlays(true)
        
        // Then
        XCTAssertTrue(UIView.isPersistentOverlaysEnabled)
        
        // Cleanup
        UIView.setPersistentOverlays(false)
        XCTAssertFalse(UIView.isPersistentOverlaysEnabled)
    }
    
    func testSwiftUIRenderOverlayDuration() {
        // Given
        let originalDuration = UIView.getOverlayDuration
        let testDuration: TimeInterval = 3.0
        
        // When
        UIView.setOverlayDuration(testDuration)
        
        // Then
        XCTAssertEqual(UIView.getOverlayDuration, testDuration)
        
        // Cleanup
        UIView.setOverlayDuration(originalDuration)
    }
    
    func testSwiftUIRenderLogging() {
        // Given
        let originalLogging = UIView.isLoggingEnabled
        
        // When
        UIView.setLoggingEnabled(false)
        
        // Then
        XCTAssertFalse(UIView.isLoggingEnabled)
        
        // When
        UIView.setLoggingEnabled(true)
        
        // Then
        XCTAssertTrue(UIView.isLoggingEnabled)
        
        // Cleanup
        UIView.setLoggingEnabled(originalLogging)
    }
    
    func testSwiftUIRenderOverlayStyle() {
        // Given
        let originalStyle = UIView.getOverlayStyle
        
        // When & Then
        UIView.setOverlayStyle(.border)
        XCTAssertEqual(UIView.getOverlayStyle, .border)
        
        UIView.setOverlayStyle(.borderWithCount)
        XCTAssertEqual(UIView.getOverlayStyle, .borderWithCount)
        
        UIView.setOverlayStyle(.none)
        XCTAssertEqual(UIView.getOverlayStyle, .none)
        
        // Cleanup
        UIView.setOverlayStyle(originalStyle)
    }
    
    func testClearSwiftUIRenderStats() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        
        // When & Then - should not crash
        UIView.clearSwiftUIRenderStats()
        
        // Cleanup
        UIView.disableSwiftUIRenderTracking()
    }
    
    func testClearAllPersistentOverlays() {
        // Given
        UIView.setPersistentOverlays(true)
        
        // When & Then - should not crash
        UIView.clearAllPersistentOverlays()
        
        // Cleanup
        UIView.setPersistentOverlays(false)
    }
    
    func testSwiftUIRenderTrackingConfiguration() {
        // Test that all configuration methods work together
        
        // Given
        UIView.disableSwiftUIRenderTracking()
        UIView.setPersistentOverlays(false)
        UIView.setOverlayDuration(1.0)
        UIView.setLoggingEnabled(true)
        UIView.setOverlayStyle(.borderWithCount)
        
        // When
        UIView.enableSwiftUIRenderTracking()
        UIView.setPersistentOverlays(true)
        UIView.setOverlayDuration(2.5)
        UIView.setLoggingEnabled(false)
        UIView.setOverlayStyle(.border)
        
        // Then
        XCTAssertTrue(UIView.isSwiftUIRenderTrackingEnabled)
        XCTAssertTrue(UIView.isPersistentOverlaysEnabled)
        XCTAssertEqual(UIView.getOverlayDuration, 2.5)
        XCTAssertFalse(UIView.isLoggingEnabled)
        XCTAssertEqual(UIView.getOverlayStyle, .border)
        
        // Cleanup
        UIView.disableSwiftUIRenderTracking()
        UIView.setPersistentOverlays(false)
        UIView.setOverlayDuration(1.0)
        UIView.setLoggingEnabled(true)
        UIView.setOverlayStyle(.borderWithCount)
    }
}


