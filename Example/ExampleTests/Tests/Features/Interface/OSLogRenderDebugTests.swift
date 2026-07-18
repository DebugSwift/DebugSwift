//
//  OSLogRenderDebugTests.swift
//  DebugSwift
//
//  Regression tests for the 3D snapshot render path when the inspected
//  SwiftUI hierarchy is wrapped in a ScrollView (e.g. the OSLog Console Test
//  screen). Before the fix, a ScrollView's _UIHostingView exposed only SwiftUI
//  internal UIKit subviews (PlatformContainer, HostingScrollView, …), so the
//  3D view collapsed to a single flat card and the buttons inside were never
//  separated.
//

import XCTest
import SwiftUI
import UIKit
@testable import DebugSwift

@MainActor
final class OSLogRenderDebugTests: XCTestCase {
    /// Mirrors the OSLogTestView structure: ScrollView > VStack { Button×6 }.
    private struct ScrollViewButtonsView: View, BodyAccessible {
        var body: some View {
            ScrollView {
                VStack(spacing: 12) {
                    Button("Log Info Message") {}
                    Button("Log Debug Message") {}
                    Button("Log Warning Message") {}
                    Button("Log Error Message") {}
                    Button("Log 10 Messages") {}
                    Button("Log Different Subsystems") {}
                }
                .padding(.horizontal)
            }
        }
    }

    private func makeHostingView<V: View>(_ rootView: V) -> UIView {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let hostingController = UIHostingController(rootView: rootView)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()
        return hostingController.view
    }

    /// Collects Button SwiftUIElements whose displayName is exactly "Button",
    /// treating a Button as a leaf (don't recurse into its label/style internals).
    private func collectButtons(from element: Element) -> [SwiftUIElement] {
        var buttons: [SwiftUIElement] = []
        if let swift = element as? SwiftUIElement, swift.label.name == "Button" {
            buttons.append(swift)
            return buttons
        }
        for child in element.children {
            buttons.append(contentsOf: collectButtons(from: child))
        }
        return buttons
    }

    // MARK: - Tests

    /// A ScrollView > VStack { Button×6 } must surface six distinct Button
    /// elements in the 3D snapshot tree — not a single flat ScrollView card.
    func testScrollViewVStackProducesSixButtonElements() {
        let hostingView = makeHostingView(ScrollViewButtonsView())
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)

        let buttons = collectButtons(from: element)
        XCTAssertEqual(buttons.count, 6, "Expected 6 Button elements, got \(buttons.count)")
    }

    /// The six buttons must have non-overlapping frames so they render as
    /// separated planes in the SceneKit 3D view, not one flat card.
    func testScrollViewButtonsHaveNonOverlappingFrames() {
        let hostingView = makeHostingView(ScrollViewButtonsView())
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)

        let buttons = collectButtons(from: element)
        XCTAssertEqual(buttons.count, 6, "Prerequisite: 6 buttons, got \(buttons.count)")
        let frames = buttons.map { $0.frame }

        for i in 0..<frames.count {
            for j in (i + 1)..<frames.count {
                XCTAssertFalse(
                    frames[i].intersects(frames[j]),
                    "Button \(i) and \(j) overlap: \(frames[i]) vs \(frames[j]) — they must be separated"
                )
            }
        }
    }

    /// The six buttons in a VStack inside a ScrollView must be stacked
    /// vertically — same X column, strictly increasing Y origins — exactly the
    /// "divide the buttons" behavior the screenshot was missing.
    func testScrollViewButtonsAreStackedVerticallyWithDistinctY() {
        let hostingView = makeHostingView(ScrollViewButtonsView())
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)

        let buttons = collectButtons(from: element)
        XCTAssertEqual(buttons.count, 6, "Prerequisite: 6 buttons, got \(buttons.count)")
        let xs = buttons.map { $0.frame.minX }
        let ys = buttons.map { $0.frame.minY }

        // Same column (VStack stacks vertically).
        let xSpread = (xs.max() ?? 0) - (xs.min() ?? 0)
        XCTAssertEqual(xSpread, 0, accuracy: 0.01, "VStack buttons should share X, got \(xs)")

        // Strictly increasing Y origins.
        XCTAssertEqual(ys, ys.sorted(), "Y origins must be increasing, got \(ys)")
        for i in 1..<ys.count {
            XCTAssertGreaterThan(ys[i], ys[i - 1], "Button \(i) must be below \(i - 1), got \(ys)")
        }
    }
}
