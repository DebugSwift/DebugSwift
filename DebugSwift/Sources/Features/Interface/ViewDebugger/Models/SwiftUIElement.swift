//
//  SwiftUIElement.swift
//  DebugSwift
//
//  Bridges the Mirror-based SwiftUI hierarchy (SwiftUIElementNode) into the
//  existing Element protocol so the View Debugger can display SwiftUI views
//  alongside UIKit views in the same hierarchy table and snapshot view.
//

import CoreGraphics
import Foundation
import SwiftUI
import UIKit

/// An element that represents a SwiftUI view, conforming to the same `Element`
/// protocol used by `ViewElement` (UIView-backed). This lets the existing
/// `HierarchyTableViewController` and `SnapshotView` display SwiftUI nodes
/// without any UI changes.
@MainActor
final class SwiftUIElement: NSObject, Element {
    private let node: SwiftUIElementNode
    private let parentFrame: CGRect

    init(node: SwiftUIElementNode, parentFrame: CGRect = .zero) {
        self.node = node
        self.parentFrame = parentFrame
        super.init()
    }

    var label: ElementLabel {
        ElementLabel(
            name: node.displayName,
            classification: node.depth == 0 ? .important : .normal
        )
    }

    var shortDescription: String {
        var desc = "SwiftUI: \(node.typeName)"
        if !node.properties.isEmpty {
            let props = node.properties.prefix(5).map { "\($0.label): \($0.valueDescription)" }
            desc += " {\(props.joined(separator: ", "))}"
        }
        return desc
    }

    var title: String {
        node.typeName
    }

    nonisolated override var description: String {
        MainActor.assumeIsolated { node.displayName }
    }

    var frame: CGRect {
        // SwiftUI views don't expose their frame without a GeometryReader.
        // Use the assigned frame — either the parent's frame or a slice
        // distributed by the parent so children appear at different
        // positions in the 3D snapshot view.
        parentFrame
    }

    var isHidden: Bool {
        false
    }

    var snapshotImage: CGImage? {
        // SwiftUI semantic nodes don't have individual pixel snapshots.
        // The snapshot is taken from the hosting UIView (the parent ViewElement).
        nil
    }

    var underlyingView: UIView? { nil }

    var children: [Element] {
        node.children.map { SwiftUIElement(node: $0, parentFrame: parentFrame) }
    }
}
