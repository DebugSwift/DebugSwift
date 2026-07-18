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

    /// The frame assigned to this node within its parent's coordinate space.
    ///
    /// SwiftUI semantic views don't expose their real frame without a
    /// GeometryReader, so the hierarchy builder assigns each node a slice
    /// of its parent's frame. This keeps siblings from overlapping in the
    /// 3D snapshot view — e.g. three buttons in a VStack get three
    /// non-overlapping vertical slices instead of all sharing the parent
    /// frame and stacking on the same X/Y in SceneKit.
    private let assignedFrame: CGRect

    /// The layout axis inherited from the nearest enclosing layout container
    /// (VStack/HStack/ZStack). Transparent SwiftUI containers (TupleView,
    /// ModifiedContent, _ConditionalContent, Group, AnyView) pass this
    /// through to their children so the real siblings get distributed along
    /// the correct axis. Defaults to `.grid` when no layout container is in
    /// the ancestor chain.
    private let inheritedLayout: Layout

    init(node: SwiftUIElementNode, parentFrame: CGRect = .zero, inheritedLayout: Layout = .grid) {
        self.node = node
        self.assignedFrame = parentFrame
        self.inheritedLayout = inheritedLayout
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
        assignedFrame
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
        // SwiftUI views don't expose real frames, so distribute this node's
        // assigned frame among its children as non-overlapping slices.
        //
        // Transparent SwiftUI wrappers (ScrollView, ModifiedContent, TupleView,
        // Group, _ConditionalContent, AnyView, ForEach, raw tuples) don't lay
        // out their content — they pass it through. If they each took a slice
        // of the parent frame, the real layout container (VStack/HStack) would
        // receive only a tiny fraction, and its buttons would be subdivided
        // into degenerate ~0px slivers (ScrollView > VStack > ModifiedContent >
        // VStack > TupleView > Button×6 divides 874px six ways → ~0px each).
        //
        // So: first flatten transparent wrappers — collect the real content
        // nodes (Buttons) that live under them — then distribute the assigned
        // frame among those real siblings. This way three buttons in a VStack
        // (even nested under ScrollView > ModifiedContent > TupleView) each
        // get a full vertical slice of the VStack's frame.
        let flattened = SwiftUIElement.flattenedChildren(of: node)
        let childLayout = SwiftUIElement.childLayout(for: node, inherited: inheritedLayout)
        let childFrames = SwiftUIElement.distributeFrames(
            count: flattened.count,
            in: assignedFrame,
            layout: childLayout
        )
        return zip(flattened, childFrames).map { child, frame in
            SwiftUIElement(node: child, parentFrame: frame, inheritedLayout: childLayout)
        }
    }

    /// Recursively flattens transparent SwiftUI wrappers, returning the real
    /// content nodes. A transparent wrapper's children replace it, and any of
    /// those children that are themselves transparent are flattened too — so
    // VStack > TupleView > Button×6 yields the six Buttons directly, and
    // ScrollView > ModifiedContent > VStack yields the VStack.
    static func flattenedChildren(of node: SwiftUIElementNode) -> [SwiftUIElementNode] {
        var result: [SwiftUIElementNode] = []
        for child in node.children {
            if isTransparentWrapper(child.typeName) {
                result.append(contentsOf: flattenedChildren(of: child))
            } else {
                result.append(child)
            }
        }
        return result
    }

    /// Transparent SwiftUI wrappers that pass their content through without
    /// laying it out. Their children are flattened into the parent so only the
    /// real layout containers (VStack/HStack/ZStack) subdivide the frame.
    static func isTransparentWrapper(_ typeName: String) -> Bool {
        // True pass-through wrappers: they don't lay out content themselves.
        // List/Form/LazyVStack/LazyHStack DO lay out content (vertically or
        // horizontally) and are handled by childLayout, not flattened here.
        // A raw Swift tuple "(A, B, C)" (the TupleView's unwrapped content)
        // also just groups its elements — flatten it so its children become
        // the enclosing layout container's direct children.
        //
        // Match by prefix/contains carefully: a VStack<TupleView<…>> or
        // HStack<…, TupleView<…>> *contains* "TupleView" but is a real layout
        // container, so use hasPrefix for TupleView and exclude the stack
        // containers explicitly.
        if typeName.contains("VStack") || typeName.contains("HStack") || typeName.contains("ZStack") {
            return false
        }
        return typeName.contains("ScrollView") ||
            typeName.contains("ModifiedContent") ||
            typeName.hasPrefix("TupleView") ||
            typeName.hasPrefix("(") ||
            typeName.contains("Group") ||
            typeName.contains("_ConditionalContent") ||
            typeName.contains("AnyView") ||
            typeName.contains("ForEach")
    }

    /// Builds the top-level SwiftUI element children for a reflected tree,
    /// distributing `frame` among the tree's children as non-overlapping
    /// slices laid out along the axis inferred from `tree`'s type (VStack →
    /// vertical, HStack → horizontal, …). Used at the UIKit→SwiftUI boundary
    /// (ViewElement hosting-view fallback) so top-level siblings don't all
    /// share the parent frame and overlap in the 3D scene.
    static func elements(for tree: SwiftUIElementNode, in frame: CGRect) -> [SwiftUIElement] {
        // Flatten transparent wrappers at the root too, so the top-level
        // siblings are the real content nodes (e.g. a ScrollView's buttons,
        // not the ScrollView→ModifiedContent→VStack nesting).
        let flattened = flattenedChildren(of: tree)
        let childLayout = childLayout(for: tree, inherited: .grid)
        let childFrames = distributeFrames(
            count: flattened.count,
            in: frame,
            layout: childLayout
        )
        return zip(flattened, childFrames).map { child, childFrame in
            SwiftUIElement(node: child, parentFrame: childFrame, inheritedLayout: childLayout)
        }
    }

    // MARK: - Frame distribution

    enum Layout {
        case vertical   // VStack
        case horizontal  // HStack
        case grid        // unknown / mixed
    }

    /// Infers a distribution layout from the SwiftUI container type name.
    static func inferredLayout(for typeName: String) -> Layout {
        if typeName.contains("VStack") { return .vertical }
        if typeName.contains("HStack") { return .horizontal }
        if typeName.contains("ZStack") { return .vertical } // depth-stack: tile vertically
        return .grid
    }

    /// Determines which layout to use for a node's *children*.
    ///
    /// A layout container (VStack/HStack/ZStack) sets the axis for its
    /// children. Transparent SwiftUI containers (TupleView, ModifiedContent,
    /// _ConditionalContent, Group, AnyView) don't impose a layout — they
    /// pass the inherited axis through so the real siblings get distributed
    /// along the enclosing container's axis. Anything else passes the
    /// inherited axis through unchanged (defaults to `.grid`).
    static func childLayout(for node: SwiftUIElementNode, inherited: Layout) -> Layout {
        let typeName = node.typeName
        if typeName.contains("VStack") || typeName.contains("ZStack") { return .vertical }
        if typeName.contains("HStack") { return .horizontal }
        // List / Form / LazyVStack lay content out vertically; LazyHStack
        // horizontally. ScrollView content flows vertically by default (and
        // its horizontal-scroll variant is rare); treat it as vertical so the
        // buttons inside a ScrollView > VStack stack vertically even when the
        // ScrollView is the root node passed to elements(for:).
        if typeName.contains("List") || typeName.contains("Form") || typeName.contains("LazyVStack") || typeName.contains("ScrollView") {
            return .vertical
        }
        if typeName.contains("LazyHStack") { return .horizontal }
        // Transparent containers pass the inherited layout through.
        return inherited
    }

    /// Splits `frame` into `count` non-overlapping sub-rectangles laid out
    /// along the inferred axis. Returns the slices in order. For an empty or
    /// single child the whole frame is returned (or an empty list when count
    /// is zero). A small inset keeps sibling planes visually separated.
    static func distributeFrames(
        count: Int,
        in frame: CGRect,
        layout: Layout,
        inset: CGFloat = 4
    ) -> [CGRect] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [frame] }

        let spacing: CGFloat = inset
        switch layout {
        case .vertical:
            let totalSpacing = spacing * CGFloat(count - 1)
            let available = max(0, frame.height - totalSpacing)
            let rowHeight = available / CGFloat(count)
            return (0..<count).map { i in
                let originY = frame.minY + (rowHeight + spacing) * CGFloat(i)
                return CGRect(
                    x: frame.minX,
                    y: originY,
                    width: frame.width,
                    height: rowHeight
                )
            }
        case .horizontal:
            let totalSpacing = spacing * CGFloat(count - 1)
            let available = max(0, frame.width - totalSpacing)
            let colWidth = available / CGFloat(count)
            return (0..<count).map { i in
                let originX = frame.minX + (colWidth + spacing) * CGFloat(i)
                return CGRect(
                    x: originX,
                    y: frame.minY,
                    width: colWidth,
                    height: frame.height
                )
            }
        case .grid:
            // Tile into the most square-ish grid we can.
            let columns = Int(ceil(sqrt(CGFloat(count))))
            let rows = Int(ceil(CGFloat(count) / CGFloat(columns)))
            let cellWidth = frame.width / CGFloat(columns)
            let cellHeight = frame.height / CGFloat(rows)
            return (0..<count).map { i in
                let col = i % columns
                let row = i / columns
                return CGRect(
                    x: frame.minX + cellWidth * CGFloat(col),
                    y: frame.minY + cellHeight * CGFloat(row),
                    width: cellWidth,
                    height: cellHeight
                )
            }
        }
    }
}
