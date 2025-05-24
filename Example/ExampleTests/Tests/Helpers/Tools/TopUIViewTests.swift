//
//  TopUIViewTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 21/12/2024.
//  Based on Given methodology

import Testing
import UIKit
@testable import DebugSwift

struct TopUIViewTests {

    @Test("Toggle with true")
    @MainActor
    func toggleWithTrue() async {
        let topLevelViewWrapper = TopLevelViewWrapper()
        topLevelViewWrapper.toggle(with: true)
        #expect(topLevelViewWrapper.isHidden == false)
        #expect(topLevelViewWrapper.alpha == 1.0)
    }

    @Test("Toggle with false")
    @MainActor
    func toggleWithFalse() async {
        let topLevelViewWrapper = TopLevelViewWrapper()
        topLevelViewWrapper.toggle(with: false)
        #expect(topLevelViewWrapper.alpha == 0.0)
        #expect(topLevelViewWrapper.superview == nil)
    }

    @Test("Show widget window")
    @MainActor
    func showWidgetWindow() async {
        let topLevelViewWrapper = TopLevelViewWrapper()
        topLevelViewWrapper.showWidgetWindow()
        #expect(topLevelViewWrapper.alpha == 1.0)
        #expect(WindowManager.window.rootViewController?.view.subviews.contains(topLevelViewWrapper) ?? false == true)
    }

    @Test("Remove widget window")
    @MainActor
    func removeWidgetWindow() async {
        let topLevelViewWrapper = TopLevelViewWrapper()
        topLevelViewWrapper.showWidgetWindow()
        topLevelViewWrapper.removeWidgetWindow()
        #expect(WindowManager.window.rootViewController?.view.subviews.contains(topLevelViewWrapper) ?? false == false)
    }
}
