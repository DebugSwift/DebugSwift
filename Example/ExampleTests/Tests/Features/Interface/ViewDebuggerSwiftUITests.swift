//
//  ViewDebuggerSwiftUITests.swift
//  DebugSwift
//
//  Integration tests verifying that the View Debugger correctly reflects
//  the semantic SwiftUI view hierarchy (VStack, Text, Button, etc.) instead
//  of internal UIKit infrastructure classes (DisplayList.View, PlatformView).
//

import XCTest
import SwiftUI
import UIKit
@testable import DebugSwift

@MainActor
final class ViewDebuggerSwiftUITests: XCTestCase {

    /// A simple SwiftUI view with recognizable semantic content.
    private struct TestContentView: View, BodyAccessible {
        var body: some View {
            VStack {
                Text("Hello World")
                Button("Tap Me") { }
            }
        }
    }

    /// A deeper view hierarchy for nesting tests.
    private struct NestedContentView: View, BodyAccessible {
        var body: some View {
            NavigationView {
                VStack {
                    HStack {
                        Text("Left")
                        Text("Right")
                    }
                    Button("Action") { }
                }
                .navigationTitle("Test")
            }
        }
    }

    /// A view using ModifiedContent (modifiers).
    private struct ModifiedContentView: View, BodyAccessible {
        var body: some View {
            Text("Styled")
                .padding()
                .foregroundColor(.red)
        }
    }

    // MARK: - Helpers

    /// Creates a real UIHostingController in a UIWindow so the responder chain
    /// works, then returns the _UIHostingView.
    private func makeHostingView<V: View>(_ rootView: V) -> UIView {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let hostingController = UIHostingController(rootView: rootView)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        // Force layout so subviews are populated
        hostingController.view.layoutIfNeeded()
        return hostingController.view
    }

    // MARK: - Tests

    /// The core regression test: a ViewElement wrapping a _UIHostingView should
    /// produce SwiftUIElement children (semantic views), NOT ViewElement children
    /// (UIKit infrastructure views like DisplayList.View).
    func testSwiftUIViewElementProducesSemanticChildren() {
        let hostingView = makeHostingView(TestContentView())

        // Create a ViewElement wrapping the hosting view
        let element = ViewElement(view: hostingView)
        let children = element.children

        // Before the fix, children would be ViewElement instances wrapping
        // DisplayList.View / PlatformView. After the fix, they should be
        // SwiftUIElement instances wrapping semantic SwiftUI views.
        XCTAssertTrue(
            children.contains { $0 is SwiftUIElement },
            "Expected at least one SwiftUIElement child, but got: \(children.map { type(of: $0) })"
        )
    }

    /// The hierarchy should contain recognizable SwiftUI view type names
    /// (VStack, Text, Button) — not UIKit infrastructure class names.
    func testHierarchyContainsSemanticSwiftUIViewNames() {
        let hostingView = makeHostingView(TestContentView())
        let element = ViewElement(view: hostingView)

        let allLabels = collectAllLabels(from: element)
        let allNames = allLabels.joined(separator: ", ")

        // Should NOT contain UIKit infrastructure names
        XCTAssertFalse(
            allLabels.contains { $0.contains("DisplayList") || $0.contains("PlatformView") || $0.contains("ViewGraph") },
            "Hierarchy should not contain UIKit infrastructure class names, but found: \(allNames)"
        )

        // Should contain SwiftUI semantic names
        // The tree may have wrappers (AnyView, ModifiedContent, etc.) but
        // should eventually contain VStack/Text/Button somewhere.
        let hasSemanticView = allLabels.contains { label in
            label.contains("VStack") || label.contains("Text") || label.contains("Button")
        }
        XCTAssertTrue(
            hasSemanticView,
            "Expected semantic SwiftUI view names (VStack/Text/Button) in: \(allNames)"
        )
    }

    /// A nested hierarchy should produce a deep tree with HStack children.
    func testNestedHierarchyProducesDeepTree() {
        let hostingView = makeHostingView(NestedContentView())
        let element = ViewElement(view: hostingView)

        let allLabels = collectAllLabels(from: element)
        let allNames = allLabels.joined(separator: ", ")

        // Should contain HStack from the nested content
        XCTAssertTrue(
            allLabels.contains { $0.contains("HStack") },
            "Expected HStack in nested hierarchy: \(allNames)"
        )
    }

    /// ModifiedContent (view modifiers) should be unwrapped to show the
    /// underlying view (Text).
    func testModifiedContentIsUnwrapped() {
        let hostingView = makeHostingView(ModifiedContentView())
        let element = ViewElement(view: hostingView)

        let allLabels = collectAllLabels(from: element)
        let allNames = allLabels.joined(separator: ", ")

        // Should contain Text (the wrapped content), possibly inside
        // ModifiedContent wrappers.
        XCTAssertTrue(
            allLabels.contains { $0.contains("Text") },
            "Expected Text inside ModifiedContent hierarchy: \(allNames)"
        )
    }

    /// A plain UIView (non-SwUI) should still use the subviews path.
    func testNonSwiftUIViewUsesSubviewsPath() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let subview1 = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let subview2 = UIView(frame: CGRect(x: 50, y: 0, width: 50, height: 50))
        view.addSubview(subview1)
        view.addSubview(subview2)

        let element = ViewElement(view: view)
        let children = element.children

        // All children should be ViewElement (UIKit path), not SwiftUIElement
        XCTAssertTrue(
            children.allSatisfy { $0 is ViewElement },
            "Non-SwiftUI views should produce ViewElement children, got: \(children.map { type(of: $0) })"
        )
        XCTAssertEqual(children.count, 2, "Expected 2 subviews, got \(children.count)")
    }

    /// isSwiftUIHostingClassName should correctly identify SwiftUI hosting views.
    func testIsSwiftUIHostingClassName() {
        let hostingView = makeHostingView(TestContentView())
        let className = NSStringFromClass(type(of: hostingView))

        XCTAssertTrue(
            SwiftUIHierarchyBuilder.isSwiftUIHostingClassName(className),
            "Expected \(className) to be detected as SwiftUI hosting view"
        )

        XCTAssertFalse(
            SwiftUIHierarchyBuilder.isSwiftUIHostingClassName("UIView"),
            "UIView should not be detected as SwiftUI"
        )
        XCTAssertFalse(
            SwiftUIHierarchyBuilder.isSwiftUIHostingClassName("UILabel"),
            "UILabel should not be detected as SwiftUI"
        )
    }

    /// buildTree directly on a SwiftUI view should produce a tree with the
    /// correct root type name.
    func testBuildTreeDirectly() {
        let tree = SwiftUIHierarchyBuilder.buildTree(from: TestContentView())

        // The root should be the custom view or its body's content
        // (TestContentView conforms to BodyAccessible via View extension)
        let allLabels = collectAllLabelsFromNode(tree)
        let allNames = allLabels.joined(separator: ", ")

        XCTAssertTrue(
            allLabels.contains { $0.contains("VStack") || $0.contains("Text") || $0.contains("Button") },
            "Direct buildTree should contain semantic views: \(allNames)"
        )
    }

    /// The tree should have at least 2 levels of depth for a VStack with content.
    func testTreeDepth() {
        let tree = SwiftUIHierarchyBuilder.buildTree(from: TestContentView())

        // Walk to find the max depth
        func maxDepth(_ node: SwiftUIElementNode) -> Int {
            if node.children.isEmpty { return node.depth }
            return node.children.map { maxDepth($0) }.max() ?? node.depth
        }
        let depth = maxDepth(tree)

        XCTAssertGreaterThan(
            depth, 0,
            "Tree should have depth > 0 for a VStack with Text and Button"
        )
    }

    // MARK: - Private helpers

    /// Recursively collect all label names from an Element tree.
    private func collectAllLabels(from element: Element) -> [String] {
        var labels: [String] = []
        labels.append(element.label.name ?? "")
        for child in element.children {
            labels.append(contentsOf: collectAllLabels(from: child))
        }
        return labels
    }

    /// Recursively collect all display names from a SwiftUIElementNode tree.
    private func collectAllLabelsFromNode(_ node: SwiftUIElementNode) -> [String] {
        var labels: [String] = [node.displayName]
        for child in node.children {
            labels.append(contentsOf: collectAllLabelsFromNode(child))
        }
        return labels
    }
}
