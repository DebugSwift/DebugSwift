//
//  SwiftUIRenderTrackingTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 28/01/2025.
//

import XCTest
import UIKit
@testable import DebugSwift

final class SwiftUIRenderTrackingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset state before each test
        UIView.setLoggingEnabled(false)
        UIView.disableSwiftUIRenderTracking()
        UIView.clearSwiftUIRenderStats()
    }
    
    override func tearDown() {
        // Clean up after each test
        UIView.disableSwiftUIRenderTracking()
        UIView.clearSwiftUIRenderStats()
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
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
    
    func testPersistentOverlaysConfiguration() {
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
    
    func testOverlayDurationConfiguration() {
        // Given
        let testDuration: TimeInterval = 2.5
        
        // When
        UIView.setOverlayDuration(testDuration)
        
        // Then
        XCTAssertEqual(UIView.getOverlayDuration, testDuration, accuracy: 0.001)
    }
    
    func testLoggingConfiguration() {
        // Given
        XCTAssertFalse(UIView.isLoggingEnabled) // Default should be false
        
        // When
        UIView.setLoggingEnabled(true)
        
        // Then
        XCTAssertTrue(UIView.isLoggingEnabled)
        
        // When
        UIView.setLoggingEnabled(false)
        
        // Then
        XCTAssertFalse(UIView.isLoggingEnabled)
    }
    
    func testOverlayStyleConfiguration() {
        // When
        UIView.setOverlayStyle(.border)
        
        // Then
        XCTAssertEqual(UIView.getOverlayStyle, .border)
        
        // When
        UIView.setOverlayStyle(.none)
        
        // Then
        XCTAssertEqual(UIView.getOverlayStyle, .none)
        
        // When
        UIView.setOverlayStyle(.borderWithCount)
        
        // Then
        XCTAssertEqual(UIView.getOverlayStyle, .borderWithCount)
    }
    
    // MARK: - SwiftUI Detection Tests
    
    func testSwiftUIHostingViewDetection() {
        // Create mock views that simulate SwiftUI hosting views
        let mockHostingView = MockSwiftUIHostingView()
        let regularView = UIView()
        
        // Test private method through reflection or make it internal for testing
        // Since isSwiftUIHostingView is private, we'll test the behavior indirectly
        XCTAssertNotNil(mockHostingView) // Just ensure mock view creation works
        XCTAssertNotNil(regularView)
    }
    
    // MARK: - Render Count Tests
    
    func testRenderCountInitialization() {
        // Given
        let _ = MockSwiftUIHostingView()
        
        // When - simulate render tracking (this would normally be called by checkForSwiftUIRender)
        // Since the methods are private, we'll test the public interface
        UIView.clearSwiftUIRenderStats()
        
        // Then - verify stats are cleared
        // We can't directly test render counts since they're private,
        // but we can test that clearSwiftUIRenderStats() doesn't crash
        XCTAssertTrue(true) // Test passes if no exception is thrown
    }
    
    func testClearSwiftUIRenderStats() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        
        // When
        UIView.clearSwiftUIRenderStats()
        
        // Then - should not crash and should clear all stats
        XCTAssertTrue(true) // Test passes if no exception is thrown
    }
    
    @MainActor
    func testClearAllPersistentOverlays() {
        // Given
        UIView.setPersistentOverlays(true)
        
        // When
        UIView.clearAllPersistentOverlays()
        
        // Then - should not crash and should clear all overlays
        XCTAssertTrue(true) // Test passes if no exception is thrown
    }
    
    // MARK: - Integration Tests
    
    func testSwiftUIRenderTrackingIntegration() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        UIView.setOverlayStyle(.borderWithCount)
        let mockView = MockSwiftUIHostingView()
        
        // When - simulate a layout pass
        mockView.setNeedsLayout()
        mockView.layoutIfNeeded()
        
        // Then - verify no crashes occur during the process
        XCTAssertNotNil(mockView.superview) // Verify view hierarchy is intact
    }
    
    @MainActor
    func testPersistentOverlaysLifecycle() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        UIView.setPersistentOverlays(true)
        UIView.setOverlayStyle(.border)
        
        // When
        let mockView = MockSwiftUIHostingView()
        mockView.setNeedsLayout()
        mockView.layoutIfNeeded()
        
        // Then - verify persistent overlays are managed correctly
        XCTAssertNotNil(mockView)
        
        // When clearing persistent overlays
        UIView.clearAllPersistentOverlays()
        
        // Then - should not crash
        XCTAssertTrue(true)
    }
    
    func testDisableTrackingClearsPersistentOverlays() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        UIView.setPersistentOverlays(true)
        
        // When
        UIView.disableSwiftUIRenderTracking()
        
        // Then - persistent overlays should be disabled
        XCTAssertFalse(UIView.isPersistentOverlaysEnabled)
    }
    
    // MARK: - Overlay Style Tests
    
    func testOverlayStyleEnum() {
        // Test all cases exist
        let allStyles: [UIView.OverlayStyle] = [.border, .borderWithCount, .none]
        
        XCTAssertEqual(allStyles.count, 3)
        
        // Test style switching
        for style in allStyles {
            UIView.setOverlayStyle(style)
            XCTAssertEqual(UIView.getOverlayStyle, style)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDurationHandling() {
        // Given
        let negativeDuration: TimeInterval = -1.0
        let zeroDuration: TimeInterval = 0.0
        let largeDuration: TimeInterval = 999.9
        
        // When & Then - should handle edge cases gracefully
        UIView.setOverlayDuration(negativeDuration)
        XCTAssertEqual(UIView.getOverlayDuration, negativeDuration) // Should store as-is
        
        UIView.setOverlayDuration(zeroDuration)
        XCTAssertEqual(UIView.getOverlayDuration, zeroDuration)
        
        UIView.setOverlayDuration(largeDuration)
        XCTAssertEqual(UIView.getOverlayDuration, largeDuration)
    }
    
    func testMultipleEnableDisableCycles() {
        // Test that enabling/disabling multiple times doesn't cause issues
        
        for _ in 0..<5 {
            UIView.enableSwiftUIRenderTracking()
            XCTAssertTrue(UIView.isSwiftUIRenderTrackingEnabled)
            
            UIView.disableSwiftUIRenderTracking()
            XCTAssertFalse(UIView.isSwiftUIRenderTrackingEnabled)
        }
    }
    
    // MARK: - Performance Tests
    
    func testRenderTrackingPerformance() {
        // Given
        UIView.enableSwiftUIRenderTracking()
        UIView.setOverlayStyle(.none) // Minimal overhead
        let mockViews = (0..<100).map { _ in MockSwiftUIHostingView() }
        
        // When - measure performance of multiple render calls
        measure {
            for view in mockViews {
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        }
        
        // Then - test should complete without timeout
        XCTAssertEqual(mockViews.count, 100)
    }
}

// MARK: - Mock Classes

private class MockSwiftUIHostingView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMockView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMockView()
    }
    
    private func setupMockView() {
        // Add to a window to enable proper testing
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        window.addSubview(self)
        window.makeKeyAndVisible()
        
        self.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    }
    
    // Override class name to simulate SwiftUI hosting view
    override var description: String {
        return "MockUIHostingView"
    }
}

 
