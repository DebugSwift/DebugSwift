//
//  FloatViewManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import Testing
import UIKit
@testable import DebugSwift

struct FloatViewManagerTests {

    @Test("Setup float view controller")
    @MainActor
    func setup() async {
        // Given
        let viewController = UIViewController()

        // When
        FloatViewManager.setup(viewController)

        // Then
        #expect(FloatViewManager.shared.floatViewController == viewController)
    }

    @Test("Is showing returns correct value")
    @MainActor
    func isShowing() async {
        // When
        let isShowing = FloatViewManager.isShowing()

        // Then
        #expect(isShowing == FloatViewManager.shared.ballView.isShowing)
    }

    @Test("Show ball view")
    @MainActor
    func show() async {
        // When
        FloatViewManager.show()

        // Then
        #expect(FloatViewManager.shared.ballView.show == true)
    }

    @Test("Remove ball view")
    @MainActor
    func remove() async {
        // When
        FloatViewManager.remove()

        // Then
        #expect(FloatViewManager.shared.ballView.show == false)
    }

    @Test("Toggle ball view show state")
    @MainActor
    func toggle() async {
        // Given
        let initialShowState = FloatViewManager.shared.ballView.show

        // When
        FloatViewManager.toggle()

        // Then
        #expect(FloatViewManager.shared.ballView.show == !initialShowState)
    }

    @Test("Is showing debugger view")
    @MainActor
    func isShowingDebuggerView() async {
        // Given
        let isShowingDebuggerView = true

        // When
        FloatViewManager.isShowingDebuggerView = isShowingDebuggerView

        // Then
        #expect(FloatViewManager.shared.ballView.isHidden == isShowingDebuggerView)
    }
}
