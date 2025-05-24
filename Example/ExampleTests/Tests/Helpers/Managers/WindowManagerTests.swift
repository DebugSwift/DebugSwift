//
//  WindowManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import Testing
import UIKit
@testable import DebugSwift

struct WindowManagerTests {

    @Test("Present debugger when not showing")
    @MainActor
    func presentDebuggerWhenNotShowing() async {
        // Given
        let mockViewController = UIViewController()
        FloatViewManager.isShowingDebuggerView = false
        
        FloatViewManager.setup(mockViewController)
        
        // When
        WindowManager.presentDebugger()
        
        // Then
        #expect(FloatViewManager.isShowingDebuggerView == true)
        #expect(WindowManager.rootNavigation?.topViewController == mockViewController)
    }

    @Test("Present debugger when already showing")
    @MainActor
    func presentDebuggerWhenAlreadyShowing() async {
        // Given
        FloatViewManager.isShowingDebuggerView = true
        
        // When
        WindowManager.presentDebugger()
        
        // Then
        #expect(FloatViewManager.isShowingDebuggerView == true)
    }

    @Test("Present view debugger when showing")
    @MainActor
    func presentViewDebuggerWhenShowing() async {
        // Given
        FloatViewManager.isShowingDebuggerView = true
        
        // When
        WindowManager.presentViewDebugger()
        
        // Then
        #expect(FloatViewManager.isShowingDebuggerView == true)
    }

    @Test("Remove view debugger when showing")
    @MainActor
    func removeViewDebuggerWhenShowing() async {
        // Given
        FloatViewManager.isShowingDebuggerView = true
        
        // When
        WindowManager.removeViewDebugger()
        
        // Then
        #expect(FloatViewManager.isShowingDebuggerView == false)
    }
}
