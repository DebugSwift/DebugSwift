import XCTest
import SwiftUI
import UIKit
@testable import DebugSwift

@MainActor
final class OSLogRenderDebugTests: XCTestCase {
    /// Mirrors the real OSLogTestView: NavigationView > ScrollView > VStack of 6 Buttons.
    private struct OSLogInNavView: View {
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 12) {
                        Button("Log Info Message") { }
                        Button("Log Debug Message") { }
                        Button("Log Warning Message") { }
                        Button("Log Error Message") { }
                        Button("Log 10 Messages") { }
                        Button("Log Different Subsystems") { }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("OSLog Test")
            }
        }
    }

    private func makeWindowSnapshot() -> Snapshot {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let hostingController = UIHostingController(rootView: OSLogInNavView())
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()
        return Snapshot(element: ViewElement(view: window, useSwiftUIHierarchy: false))
    }

    private func collectButtons(from snapshot: Snapshot) -> [(String, CGRect)] {
        var buttons: [(String, CGRect)] = []
        func walk(_ node: Snapshot) {
            if node.label.name == "Button" {
                buttons.append((node.label.name ?? "", node.frame))
                return
            }
            for child in node.children { walk(child) }
        }
        walk(snapshot)
        return buttons
    }

    /// Regression: the 3D snapshot tree must reach the six SwiftUI Buttons nested
    /// under NavigationView > ScrollView > VStack. Before the rootView fix
    /// (accessed via the AnyHostingController protocol, not KVC/Mirror), the
    /// hosting view had zero children and the buttons collapsed to a single flat
    /// plane in the 3D view.
    func testNavigationViewScrollViewVStackProducesSixButtonElements() {
        let snapshot = makeWindowSnapshot()
        let buttons = collectButtons(from: snapshot)
        XCTAssertEqual(
            buttons.count,
            6,
            "Expected 6 Button elements under NavigationView>ScrollView>VStack; got \(buttons.count). "
                + "The hosting view's rootView must be reached via the AnyHostingController protocol."
        )
    }

    func testScrollViewButtonsHaveNonOverlappingFrames() {
        let snapshot = makeWindowSnapshot()
        let buttons = collectButtons(from: snapshot)
        guard buttons.count == 6 else {
            XCTFail("Prerequisite: expected 6 buttons, got \(buttons.count)")
            return
        }
        for first in 0..<buttons.count {
            for second in (first + 1)..<buttons.count {
                let firstFrame = buttons[first].1
                let secondFrame = buttons[second].1
                XCTAssertFalse(
                    firstFrame.intersects(secondFrame),
                    "Button \(first) frame \(firstFrame) overlaps Button \(second) frame \(secondFrame)"
                )
            }
        }
    }

    func testScrollViewButtonsAreStackedVerticallyWithDistinctY() {
        let snapshot = makeWindowSnapshot()
        let buttons = collectButtons(from: snapshot)
        guard buttons.count == 6 else {
            XCTFail("Prerequisite: expected 6 buttons, got \(buttons.count)")
            return
        }
        let yOrigins = buttons.map { $0.1.minY }
        let xOrigins = buttons.map { $0.1.minX }
        XCTAssertTrue(
            xOrigins.allSatisfy { abs($0 - xOrigins[0]) < 1 },
            "Buttons should share an X column in a VStack; got X=\(xOrigins)"
        )
        XCTAssertEqual(yOrigins, yOrigins.sorted(), "Button Y origins must be non-decreasing; got \(yOrigins)")
        XCTAssertEqual(Set(yOrigins).count, yOrigins.count, "Button Y origins must be distinct; got \(yOrigins)")
    }
}
