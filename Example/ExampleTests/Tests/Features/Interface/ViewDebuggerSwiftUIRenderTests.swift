//
//  ViewDebuggerSwiftUIRenderTests.swift
//  DebugSwift
//
//  Regression tests for the 3D SnapshotView render path when the inspected
//  window is a pure SwiftUI hierarchy. A `_UIHostingView` exposes no UIKit
//  subviews, so the 3D snapshot must fall back to the SwiftUI semantic tree
//  — otherwise the SnapshotView collapses to a single flat plane (no depth,
//  sliders hidden via `isLeft`).
//

import XCTest
import SwiftUI
import UIKit
@testable import DebugSwift

@MainActor
final class ViewDebuggerSwiftUIRenderTests: XCTestCase {

    /// The minimal SwiftUI surface under test: a single Button. This is the
    /// smallest hierarchy that reproduces the flat-plane render bug.
    private struct ButtonOnlyView: View, BodyAccessible {
        var body: some View {
            Button("Tap Me") {}
        }
    }

    /// Creates a real UIHostingController in a UIWindow so the responder chain
    /// works, then returns the _UIHostingView.
    private func makeHostingView<V: View>(_ rootView: V) -> UIView {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let hostingController = UIHostingController(rootView: rootView)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()
        return hostingController.view
    }

    // MARK: - Core regression: 3D snapshot tree must not be a flat plane

    /// The 3D SnapshotView uses `useSwiftUIHierarchy: false`. Before the fix,
    /// a `_UIHostingView` has zero UIKit subviews, so `Snapshot.children` was
    /// empty and the 3D view rendered a single flat plane with no depth.
    /// After the fix, the 3D path falls back to the SwiftUI semantic tree when
    /// the hosting view has no UIKit subviews, so the snapshot has children.
    func test3DSnapshotTreeHasChildrenForSwiftUIHostingView() {
        let hostingView = makeHostingView(ButtonOnlyView())

        // Sanity: the hosting view itself has no UIKit subviews — that is the
        // root cause of the flat-plane render bug.
        XCTAssertTrue(
            hostingView.subviews.isEmpty,
            "Sanity check failed: _UIHostingView should have no UIKit subviews, got \(hostingView.subviews)"
        )

        // 3D snapshot path (useSwiftUIHierarchy: false).
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)
        let children = element.children

        XCTAssertGreaterThan(
            children.count, 0,
            "3D snapshot tree for a SwiftUI hosting view must have children (was a flat plane before fix), got 0"
        )
    }

    /// The 3D snapshot tree must contain semantic SwiftUI node(s) (SwiftUIElement),
    /// not just the bare hosting view — otherwise there is no hierarchy to render.
    func test3DSnapshotTreeContainsSwiftUIElements() {
        let hostingView = makeHostingView(ButtonOnlyView())
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)

        XCTAssertTrue(
            element.children.contains { $0 is SwiftUIElement },
            "3D snapshot children should include SwiftUIElement(s) after fallback, got: \(element.children.map { type(of: $0) })"
        )
    }

    /// The rendered Snapshot tree (Snapshot(element:)) must have > 0 children,
    /// which is the exact condition SnapshotView uses to show the depth sliders
    /// (it hides them via `isLeft` when `children.first?.children.isEmpty`).
    func testRenderedSnapshotTreeHasDepth() {
        let hostingView = makeHostingView(ButtonOnlyView())
        let snapshot = Snapshot(element: ViewElement(view: hostingView, useSwiftUIHierarchy: false))

        XCTAssertGreaterThan(
            snapshot.children.count, 0,
            "Rendered Snapshot must have children for the 3D view to show depth, got 0"
        )
    }

    /// A Snapshot built from the *window* (as InAppViewDebugger does) over a
    /// SwiftUI root must also reach the SwiftUI children somewhere in the tree,
    /// not stop at a single flat hosting-view leaf.
    func testWindowSnapshotReachesSwiftUIHierarchy() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let hostingController = UIHostingController(rootView: ButtonOnlyView())
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()

        let snapshot = Snapshot(element: ViewElement(view: window, useSwiftUIHierarchy: false))

        // Recursively collect every label name in the snapshot tree.
        func collectLabels(_ s: Snapshot) -> [String] {
            var labels = [s.label.name ?? ""]
            for c in s.children { labels.append(contentsOf: collectLabels(c)) }
            return labels
        }
        let labels = collectLabels(snapshot)
        let joined = labels.joined(separator: ", ")

        // The Button semantic node should be reachable somewhere in the tree.
        XCTAssertTrue(
            labels.contains { $0.contains("Button") },
            "Window-level snapshot should reach the SwiftUI Button node after the fix, got: \(joined)"
        )
    }

    /// Regression for plain UIViews: the 3D path must still walk UIView.subviews
    /// for non-SwiftUI views and NOT synthesize SwiftUIElement children.
    func testPlainUIViewStillUsesSubviewsOn3DPath() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let subview = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.addSubview(subview)

        let element = ViewElement(view: view, useSwiftUIHierarchy: false)
        let children = element.children

        XCTAssertTrue(
            children.allSatisfy { $0 is ViewElement },
            "Plain UIView on 3D path should produce ViewElement children, got: \(children.map { type(of: $0) })"
        )
        XCTAssertEqual(children.count, 1, "Expected 1 subview, got \(children.count)")
    }

    // MARK: - Render capture: assert the 3D snapshot tree is not a flat plane

    /// `SnapshotView` hides the depth/spacing sliders via `isLeft`, which is
    /// `snapshot.children.first?.children.isEmpty` — i.e. it treats the scene
    /// as a single flat plane when the first child has no grandchildren. For a
    /// pure-SwiftUI hierarchy the 3D snapshot (useSwiftUIHierarchy: false) used
    /// to be a single leaf (the hosting view) with no children at all, so the
    /// sliders were hidden and the view was a single flat plane. After the fix,
    /// the snapshot tree must have a non-flat structure: the root must have
    /// children, and at least one of those children must itself have children
    /// (so `isLeft` is false and the 3D view shows depth).
    func test3DSnapshotTreeIsNotFlatPlane() {
        let hostingView = makeHostingView(ButtonOnlyView())
        let snapshot = Snapshot(
            element: ViewElement(view: hostingView, useSwiftUIHierarchy: false)
        )

        // The root must have children (the hosting view's SwiftUI semantic tree).
        XCTAssertGreaterThan(
            snapshot.children.count, 0,
            "3D snapshot root must have children after fix, got 0 (flat plane)"
        )

        // Mirror SnapshotView.isLeft: true means "flat plane, sliders hidden".
        // After the fix this must be false for a SwiftUI hierarchy.
        let isLeft = snapshot.children.first?.children.isEmpty != false
        XCTAssertFalse(
            isLeft,
            "3D snapshot must not be a flat plane (SnapshotView.isLeft must be false) for a SwiftUI hierarchy"
        )
    }

    /// Counts every Snapshot node reachable from the root — the exact set of
    /// nodes SnapshotNode() turns into SceneKit nodes. Before the fix this was
    /// 1 (just the hosting-view leaf); after the fix it must be > 1.
    func test3DSnapshotTreeTotalNodeCountGreaterThanOne() {
        let hostingView = makeHostingView(ButtonOnlyView())
        let snapshot = Snapshot(
            element: ViewElement(view: hostingView, useSwiftUIHierarchy: false)
        )

        func countNodes(_ s: Snapshot) -> Int {
            1 + s.children.reduce(0) { $0 + countNodes($1) }
        }
        let total = countNodes(snapshot)

        XCTAssertGreaterThan(
            total, 1,
            "3D snapshot tree must have more than one renderable node after fix, got \(total)"
        )
    }

    // MARK: - Three buttons must be visually separated (non-overlapping frames)

    /// A VStack with three buttons — the user-facing case: three buttons must
    /// render as three separated planes in the 3D view, not stacked on the
    /// same X/Y. Before frame distribution, all SwiftUI siblings shared the
    /// parent frame and overlapped perfectly.
    private struct ThreeButtonsView: View, BodyAccessible {
        var body: some View {
            VStack {
                Button("One") {}
                Button("Two") {}
                Button("Three") {}
            }
        }
    }

    /// Collects every Button SwiftUIElement node reachable from an Element tree.
    private func collectButtons(from element: Element) -> [SwiftUIElement] {
        var buttons: [SwiftUIElement] = []
        if let swift = element as? SwiftUIElement, swift.label.name == "Button" {
            // A Button is a leaf for collection — don't recurse into its
            // label/style internals (which also contain "Button" in their
            // mangled type names and would inflate the count).
            buttons.append(swift)
            return buttons
        }
        for child in element.children {
            buttons.append(contentsOf: collectButtons(from: child))
        }
        return buttons
    }

    /// Three buttons in a VStack must produce three distinct SwiftUIElement
    /// nodes (one per button) — not collapsed into a single node.
    func testThreeButtonsProduceThreeSeparateElements() {
        let hostingView = makeHostingView(ThreeButtonsView())
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)

        let buttons = collectButtons(from: element)
        XCTAssertEqual(
            buttons.count, 3,
            "Expected 3 Button elements in the 3D tree, got \(buttons.count): \(buttons.map { $0.label.name ?? "" })"
        )
    }

    /// The three buttons must have **non-overlapping** frames so they render
    /// as separated planes in the SceneKit 3D view. Before the fix every
    /// sibling shared the parent frame and the buttons overlapped at the same
    /// X/Y (only separated by z-depth).
    func testThreeButtonFramesAreNonOverlapping() {
        let hostingView = makeHostingView(ThreeButtonsView())
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)

        let buttons = collectButtons(from: element)
        XCTAssertEqual(buttons.count, 3, "Prerequisite: 3 buttons, got \(buttons.count)")

        let frames = buttons.map { $0.frame }
        for i in 0..<frames.count {
            for j in (i + 1)..<frames.count {
                XCTAssertFalse(
                    frames[i].intersects(frames[j]),
                    "Button \(i) and \(j) frames overlap: \(frames[i]) vs \(frames[j]) — they must be separated in the 3D view"
                )
            }
        }
    }

    /// Three buttons in a VStack must be laid out **vertically** — their
    /// frames share the same X column but have distinct, increasing Y origins.
    /// This is the exact "separate the 3 buttons" behavior.
    func testThreeButtonsAreStackedVerticallyWithDistinctY() {
        let hostingView = makeHostingView(ThreeButtonsView())
        let element = ViewElement(view: hostingView, useSwiftUIHierarchy: false)

        let buttons = collectButtons(from: element)
        XCTAssertEqual(buttons.count, 3, "Prerequisite: 3 buttons, got \(buttons.count)")

        let xs = buttons.map { $0.frame.minX }
        let ys = buttons.map { $0.frame.minY }

        // Same column (VStack stacks vertically, not horizontally).
        let xSpread = xs.max()! - xs.min()!
        XCTAssertEqual(
            xSpread, 0, accuracy: 0.01,
            "VStack buttons should share the same X column, got Xs: \(xs)"
        )

        // Distinct, monotonically increasing Y origins.
        XCTAssertEqual(
            ys, ys.sorted(),
            "VStack button Y origins must be monotonically increasing, got Ys: \(ys)"
        )
        for i in 1..<ys.count {
            XCTAssertGreaterThan(
                ys[i], ys[i - 1],
                "VStack button \(i) must start below button \(i - 1), got Ys: \(ys)"
            )
        }
    }

    // MARK: - Non-KVC-compliant hosting controller must not crash

    /// A UIViewController subclass whose name contains "HostingController" but
    /// which is NOT a real `UIHostingController` and is not KVC-compliant for
    /// `rootView`. Before the fix, `swiftUITree(for:)` fell back to
    /// `value(forKey: "rootView")`, which raises `NSUnknownKeyException`
    /// (an Obj-C exception, not a Swift error) on such controllers. DebugSwift's
    /// own `UncaughtExceptionHandler` captured that as a crash, killing the app
    /// whenever the view debugger was opened on a screen using a SwiftUI-internal
    /// hosting controller (e.g. NavigationSplitView's sidebar
    /// `UIHostingController<ModifiedContent<…NavigationSearchColumnModifier…>>`).
    /// This test reproduces the shape: a controller with "HostingController" in
    /// its type name and no `rootView` key. `ViewElement.children` must not
    /// crash — it must fall back to the subview path.
    private final class FakeHostingController: UIViewController {
        // No `rootView` property, and not a real UIHostingController.
    }

    func testNonKVCCompliantHostingControllerDoesNotCrash() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let fake = FakeHostingController()
        // Force a name that contains "HostingController" so isSwiftUIHostingClassName
        // would have matched and driven swiftUITree(for:) into the old KVC path.
        window.rootViewController = fake
        window.makeKeyAndVisible()
        fake.view.layoutIfNeeded()

        // The hosting-name check is on NSStringFromClass(type(of:)), so we also
        // verify the name contains "HostingController" to confirm the test
        // actually exercises the branch.
        let className = NSStringFromClass(type(of: fake))
        XCTAssertTrue(className.contains("HostingController"), "Test setup: \(className) should contain 'HostingController'")

        // Must not crash. Before the fix this raised NSUnknownKeyException.
        let element = ViewElement(view: fake.view, useSwiftUIHierarchy: true)
        // Accessing children must not crash and must return an array (empty,
        // since FakeHostingController.view has no subviews and no SwiftUI tree).
        let children = element.children
        XCTAssertEqual(children.count, 0, "FakeHostingController with no subviews should have 0 children, got \(children.count)")
    }
}


