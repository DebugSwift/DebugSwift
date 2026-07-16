//
//  SwiftUIHierarchyBuilder.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2025.
//
//  Mirror-based SwiftUI view tree reflection.
//  Walks the declarative SwiftUI hierarchy via Mirror + body accessor,
//  bypassing the UIKit subview layer that hides semantic views.
//

import Foundation
import SwiftUI

// MARK: - BodyAccessible protocol

/// Protocol to access `body` on any `View` without generic constraints.
/// Custom SwiftUI views can conform to expose their `body` to the hierarchy builder.
/// Without this conformance, the view appears as a leaf node (still far better
/// than the subviews-only approach which shows internal infrastructure classes).
@MainActor
public protocol BodyAccessible {
    @MainActor func bodyAccessor() -> Any
}

extension View {
    @MainActor public func bodyAccessor() -> Any { body }
}

// MARK: - SwiftUIElementNode

/// A node in a reflected SwiftUI view tree.
/// Unlike UIView-based ViewElement, this walks the *declarative* SwiftUI tree
/// via Mirror reflection on the hosting controller's rootView.
public struct SwiftUIElementNode: Equatable {
    public let id: String
    public let typeName: String
    public let displayName: String
    public let depth: Int
    public let children: [SwiftUIElementNode]
    public let properties: [Property]

    public struct Property: Equatable {
        public let label: String
        public let valueDescription: String

        public init(label: String, valueDescription: String) {
            self.label = label
            self.valueDescription = valueDescription
        }
    }

    public init(
        id: String,
        typeName: String,
        displayName: String,
        depth: Int,
        children: [SwiftUIElementNode],
        properties: [Property]
    ) {
        self.id = id
        self.typeName = typeName
        self.displayName = displayName
        self.depth = depth
        self.children = children
        self.properties = properties
    }

    public static func == (lhs: SwiftUIElementNode, rhs: SwiftUIElementNode) -> Bool {
        lhs.id == rhs.id && lhs.typeName == rhs.typeName && lhs.displayName == rhs.displayName
            && lhs.depth == rhs.depth && lhs.children == rhs.children && lhs.properties == rhs.properties
    }
}

// MARK: - SwiftUIHierarchyBuilder

/// The core engine. Given any SwiftUI view value, reflect its tree structure.
/// This runs on `UIHostingController.rootView` to build the semantic hierarchy
/// that `UIView.subviews` cannot expose.
@MainActor
public enum SwiftUIHierarchyBuilder {

    /// Build a tree from a SwiftUI view value.
    /// - Parameters:
    ///   - view: The root SwiftUI view (e.g. UIHostingController.rootView).
    ///   - maxDepth: Maximum recursion depth to prevent infinite loops.
    ///   - includeProperties: Whether to extract leaf properties (text, color, etc.).
    /// - Returns: A hierarchy node representing the view tree.
    public static func buildTree(
        from view: Any,
        maxDepth: Int = 50,
        includeProperties: Bool = true
    ) -> SwiftUIElementNode {
        buildNode(from: view, depth: 0, maxDepth: maxDepth, includeProperties: includeProperties, path: "root")
    }

    static func buildNode(
        from value: Any,
        depth: Int,
        maxDepth: Int,
        includeProperties: Bool,
        path: String
    ) -> SwiftUIElementNode {
        let mirror = Mirror(reflecting: value)
        let typeName = cleanTypeName(String(describing: type(of: value)))
        let displayName = displayName(for: value, typeName: typeName, mirror: mirror)

        var childNodes: [SwiftUIElementNode] = []
        var properties: [SwiftUIElementNode.Property] = []

        guard depth < maxDepth else {
            return SwiftUIElementNode(
                id: path, typeName: typeName, displayName: displayName,
                depth: depth, children: [], properties: []
            )
        }

        // 0. For custom views (body is a computed property invisible to Mirror),
        //    call the body accessor. We use a runtime check: if the value's type
        //    conforms to View, we can call bodyAccessor() via the View extension.
        //    The `as? BodyAccessible` cast fails because View doesn't explicitly
        //    conform to BodyAccessible, so we use the bodyAccessor() method directly
        //    via dynamic dispatch on the protocol extension.
        if let bodyValue = extractBody(from: value) {
            if isSwiftUIViewType(value: bodyValue) {
                childNodes.append(buildNode(
                    from: bodyValue, depth: depth + 1, maxDepth: maxDepth,
                    includeProperties: includeProperties, path: "\(path).body"
                ))
            }
        }

        // 1. Drill into SwiftUI's internal _tree wrapper (HStack/VStack/ZStack use it).
        //    Tree<_HStackLayout, TupleView<...>> → the content is the second generic.
        if let treeChild = mirror.children.first(where: { $0.label == "_tree" }) {
            childNodes.append(contentsOf: extractTreeChildren(
                from: treeChild.value, depth: depth + 1, maxDepth: maxDepth,
                includeProperties: includeProperties, path: "\(path)._tree"
            ))
        }

        // 2. For TupleView, drill into its content to find the individual views.
        if typeName.contains("TupleView") {
            childNodes.append(contentsOf: extractTupleChildren(
                from: value, depth: depth + 1, maxDepth: maxDepth,
                includeProperties: includeProperties, path: "\(path).tuple"
            ))
        }

        // 3. For _ConditionalContent (if/else in ViewBuilder), both branches are stored.
        if typeName.contains("_ConditionalContent") {
            for child in mirror.children {
                if isSwiftUIViewType(value: child.value) {
                    childNodes.append(buildNode(
                        from: child.value, depth: depth + 1, maxDepth: maxDepth,
                        includeProperties: includeProperties, path: "\(path).cond"
                    ))
                }
            }
        }

        // 4. For ModifiedContent, drill into its content (the wrapped view).
        if typeName.contains("ModifiedContent"),
           let contentChild = mirror.children.first(where: { $0.label == "content" })
        {
            childNodes.append(buildNode(
                from: contentChild.value, depth: depth + 1, maxDepth: maxDepth,
                includeProperties: includeProperties, path: "\(path).content"
            ))
        }

        // 5. Generic Mirror walk for stored properties that are views or leaf properties.
        for (index, child) in mirror.children.enumerated() {
            let label = child.label ?? "\(index)"
            // Skip already-handled internal wrappers
            if label == "_tree" { continue }
            if label == "content" && typeName.contains("ModifiedContent") { continue }

            if isSwiftUIViewType(value: child.value) {
                childNodes.append(buildNode(
                    from: child.value, depth: depth + 1, maxDepth: maxDepth,
                    includeProperties: includeProperties, path: "\(path).\(label)"
                ))
            } else if includeProperties {
                let desc = String(describing: child.value)
                if !desc.contains("nil") && desc.count <= 200 {
                    properties.append(.init(label: label, valueDescription: desc))
                }
            }
        }

        return SwiftUIElementNode(
            id: path, typeName: typeName, displayName: displayName,
            depth: depth, children: childNodes, properties: properties
        )
    }

    /// Extract children from SwiftUI's internal `Tree<Layout, Content>` wrapper.
    static func extractTreeChildren(
        from treeValue: Any,
        depth: Int,
        maxDepth: Int,
        includeProperties: Bool,
        path: String
    ) -> [SwiftUIElementNode] {
        let treeMirror = Mirror(reflecting: treeValue)
        var nodes: [SwiftUIElementNode] = []

        for child in treeMirror.children {
            if isSwiftUIViewType(value: child.value) {
                nodes.append(buildNode(
                    from: child.value, depth: depth, maxDepth: maxDepth,
                    includeProperties: includeProperties, path: "\(path).\(child.label ?? "")"
                ))
            }
        }
        return nodes
    }

    /// Extract children from a TupleView's content.
    static func extractTupleChildren(
        from tupleValue: Any,
        depth: Int,
        maxDepth: Int,
        includeProperties: Bool,
        path: String
    ) -> [SwiftUIElementNode] {
        let tupleMirror = Mirror(reflecting: tupleValue)
        var nodes: [SwiftUIElementNode] = []

        for (index, child) in tupleMirror.children.enumerated() {
            if isSwiftUIViewType(value: child.value) {
                nodes.append(buildNode(
                    from: child.value, depth: depth, maxDepth: maxDepth,
                    includeProperties: includeProperties, path: "\(path).\(index)"
                ))
            }
        }
        return nodes
    }

    /// Detect if a UIView (in production) is a SwiftUI hosting view.
    public static func isSwiftUIHostingClassName(_ className: String) -> Bool {
        className.contains("UIHosting") ||
            className.contains("_UIHosting") ||
            className.contains("SwiftUI.") ||
            className.contains("ViewHost") ||
            className.contains("PlatformView") ||
            className.contains("DisplayList") ||
            className.contains("ViewGraph") ||
            className.contains("ModifiedContent") ||
            className.contains("CellHostingView") ||
            className.contains("HostingView")
    }

    /// Determine if a value is a SwiftUI view type by checking for `View` conformance
    /// or known SwiftUI type patterns.
    static func isSwiftUIViewType(value: Any) -> Bool {
        let typeName = String(describing: type(of: value))

        let viewPatterns = [
            "VStack", "HStack", "ZStack", "List", "ScrollView", "ForEach",
            "NavigationStack", "NavigationView", "TabView", "Group",
            "Text", "Image", "Button", "TextField", "Toggle", "Slider",
            "Stepper", "DatePicker", "Picker", "Label", "Spacer",
            "Divider", "Color", "Shape", "Map", "SecureField", "Link",
            "NavigationLink", "Menu", "ContextMenu", "Sheet", "Alert",
            "ModifiedContent", "_ConditionalContent", "Optional", "Group",
            "LazyVStack", "LazyHStack", "LazyVGrid", "LazyHGrid",
            "DisclosureGroup", "Section", "Form", "Grid", "GridRow",
            "ViewThatFits", "AnyView", "TupleView", "_TupleView"
        ]

        for pattern in viewPatterns where typeName.contains(pattern) {
            return true
        }

        if typeName.hasSuffix("View") || typeName.hasSuffix("View>") {
            return true
        }

        let mirror = Mirror(reflecting: value)
        if mirror.children.contains(where: { $0.label == "body" }) {
            return true
        }

        return false
    }


    /// Clean up internal Swift type name mangling for display.
    static func cleanTypeName(_ name: String) -> String {
        var cleaned = name
        if cleaned.hasPrefix("SwiftUI.") {
            cleaned = String(cleaned.dropFirst("SwiftUI.".count))
        }
        return cleaned
    }

    /// Generate a human-friendly display name.
    static func displayName(for value: Any, typeName: String, mirror: Mirror) -> String {
        if typeName.hasPrefix("Text") || typeName == "Text" {
            for child in mirror.children {
                if child.label == "anyTextStorage" || child.label == "text" {
                    let textDesc = String(describing: child.value)
                    if textDesc != "Optional(Optional(nil))" && !textDesc.contains("nil") {
                        return "Text(\"\(textDesc)\")"
                    }
                }
            }
        }

        if typeName.hasPrefix("Button") {
            return "Button"
        }

        if ["VStack", "HStack", "ZStack"].contains(where: { typeName.hasPrefix($0) }) {
            return typeName.split(separator: "<").first.map(String.init) ?? typeName
        }

        return typeName
    }

    /// Flatten the tree into a list (for table view display).
    public static func flatten(_ node: SwiftUIElementNode) -> [SwiftUIElementNode] {
        var result: [SwiftUIElementNode] = [node]
        for child in node.children {
            result.append(contentsOf: flatten(child))
        }
        return result
    }

    /// Count total nodes in the tree.
    public static func count(_ node: SwiftUIElementNode) -> Int {
        1 + node.children.reduce(0) { $0 + count($1) }
    }

    /// Find nodes by type name pattern.
    public static func find(_ node: SwiftUIElementNode, typeName contains: String) -> [SwiftUIElementNode] {
        var result: [SwiftUIElementNode] = []
        if node.typeName.contains(contains) {
            result.append(node)
        }
        for child in node.children {
            result.append(contentsOf: find(child, typeName: contains))
        }
        return result
    }
}
// MARK: - Body extraction

/// Extracts the `body` from a SwiftUI View value.
/// Custom views must conform to `BodyAccessible` to expose their computed `body`
/// property (Mirror only sees stored properties, not computed ones).
/// Built-in SwiftUI views (VStack, Text, etc.) expose their content via
/// stored properties like `_tree`, which the Mirror walk handles directly.
@MainActor
private func extractBody(from value: Any) -> Any? {
    if let bodyful = value as? BodyAccessible {
        return bodyful.bodyAccessor()
    }
    return nil
}
