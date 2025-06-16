//
//  ViewElement.swift
//  LiveSnapshot
//
//  Created by Indragie Karunaratne on 3/30/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

/// An element that represents a UIView.
@MainActor
final class ViewElement: NSObject, Element {
    var label: ElementLabel {
        guard let view else {
            return ElementLabel(name: nil)
        }
        if let viewController = getViewController(view: view) {
            let name = "\(String(describing: Swift.type(of: viewController))) (\(String(describing: Swift.type(of: view))))"
            return ElementLabel(name: name, classification: .important)
        }
        return ElementLabel(name: String(describing: Swift.type(of: view)))
    }

    var frame: CGRect {
        let offset = contentOffsetForView(view)
        return view?.frame.offsetBy(dx: offset.x, dy: offset.y) ?? .zero
    }

    var isHidden: Bool {
        view?.isHidden ?? false
    }

    var snapshotImage: CGImage? {
        guard let view else {
            return nil
        }
        return snapshotView(view)
    }

    var children: [Element] {
        guard let view else {
            return []
        }
        return view.subviews.map { ViewElement(view: $0) }
    }

    var title: String {
        guard let view else { return "No view available" }
        return NSStringFromClass(type(of: view))
    }

    var shortDescription: String {
        guard let view else { return "No view available" }

        let frame = view.frame
        let className = NSStringFromClass(type(of: view))

        return String(
            format: "Class: %@, Frame: (%.1f, %.1f, %.1f, %.1f)",
            className,
            frame.origin.x,
            frame.origin.y,
            frame.size.width,
            frame.size.height
        )
    }

    nonisolated override var description: String {
        MainActor.assumeIsolated {
            guard let view else { return "No view available" }

            let frame = view.frame
            let className = NSStringFromClass(type(of: view))
            let alpha = view.alpha
            let backgroundColor = view.backgroundColor?.hexString ?? "No background color"
            let tag = view.tag
            var additionalInfo = ""

            // 1. Accessibility Information
            if let accessibilityLabel = view.accessibilityLabel {
                additionalInfo += "\nAccessibility Label: \(accessibilityLabel)"
            }
            if let accessibilityHint = view.accessibilityHint {
                additionalInfo += "\nAccessibility Hint: \(accessibilityHint)"
            }
            if view.isAccessibilityElement {
                additionalInfo += "\nAccessibility Traits: \(view.accessibilityTraits.rawValue)"
            }

            // 2. Subviews and Hierarchy
            if !view.subviews.isEmpty {
                let subviewsInfo = view.subviews.map { NSStringFromClass(type(of: $0)) }.joined(separator: ", ")
                additionalInfo += "\nSubviews: \(subviewsInfo)"
            }

            // 3. Gesture Recognizers
            if let gestureRecognizers = view.gestureRecognizers, !gestureRecognizers.isEmpty {
                let gestureTypes = gestureRecognizers.map { NSStringFromClass(type(of: $0)) }.joined(separator: ", ")
                additionalInfo += "\nGesture Recognizers: \(gestureTypes)"
            }

            // 4. Control State
            if let control = view as? UIControl {
                let stateInfo = "Current State: \(control.state.rawValue)"
                additionalInfo += "\n\(stateInfo)"
            }

            // 5. Content Mode
            additionalInfo += "\nContent Mode: \(view.contentMode.rawValue)"

            // 6. Layer Information (customize based on your needs)
            let layer = view.layer
            let layerInfo = """
            Border Width: \(layer.borderWidth)
            Corner Radius: \(layer.cornerRadius)
            Shadow Opacity: \(layer.shadowOpacity)
            """
            additionalInfo += "\n\n- Layer Info: \n\(layerInfo)\n"

            if let tintColor = view.tintColor?.hexString {
                additionalInfo += "\nTint: \(tintColor)"
            }

            // Check if the view is a UIButton
            if let button = view as? UIButton {
                // Additional UIButton information
                var buttonInfo = """
                Title: \(button.title(for: .normal) ?? "No title")
                Title Color: \((button.titleColor(for: .normal) ?? UIColor.black).hexString)
                """

                // Check if the button has an image
                if let buttonImage = button.image(for: .normal) {
                    buttonInfo += "\nImage: \(buttonImage)"
                } else {
                    buttonInfo += "\nNo Image"
                }

                // Include the state information
                let stateInfo = "Current State: \(button.state.rawValue)"
                buttonInfo += "\n\(stateInfo)"

                additionalInfo += "\n\n- UIButton Info: \n\(buttonInfo)\n"
            }

            // Check if the view is a UILabel
            if let label = view as? UILabel {
                // Additional UILabel information
                let labelInfo = """
                Text: \(label.text ?? "No text")
                Font: \(label.font.fontName) - Size: \(label.font.pointSize)
                Text Color: \(label.textColor?.hexString ?? "No color")
                """

                additionalInfo += "\n\n- UILabel Info: \n\(labelInfo)\n"
            }

            if let imageView = view as? UIImageView {
                // Additional UIImageView information
                let imageViewInfo = """
                Image: \(imageView.image?.description ?? "No image")
                Content Mode: \(imageView.contentMode.rawValue)
                Is Animating: \(imageView.isAnimating)
                """

                additionalInfo += "\n\n- UIImageView Info: \n\(imageViewInfo)\n"
            }

            if let textView = view as? UITextView {
                // Additional UITextView information
                let textViewInfo = """
                Text: \(textView.text ?? "No text")
                Font: \(textView.font?.description ?? "No font")
                Text Color: \(textView.textColor?.description ?? "No color")
                Is Editable: \(textView.isEditable)
                """

                additionalInfo += "\n\n- UITextView Info: \n\(textViewInfo)\n"
            }

            if let textField = view as? UITextField {
                let textFieldInfo = """
                Text: \(textField.text ?? "No text")
                Placeholder: \(textField.placeholder ?? "No placeholder")
                Font: \(textField.font?.description ?? "No font")
                Text Color: \(textField.textColor?.description ?? "No color")
                Is Editing: \(textField.isEditing)
                """

                additionalInfo += "\n\n- UITextField Info: \n\(textFieldInfo)\n"
            }

            // Additional UISearchBar information
            if let searchBar = view as? UISearchBar {
                let searchBarInfo = """
                Text: \(searchBar.text ?? "No text")
                Placeholder: \(searchBar.placeholder ?? "No placeholder")
                """

                additionalInfo += "\n\n- UISearchBar Info: \n\(searchBarInfo)\n"
            }

            // Additional UITableView information
            if let tableView = view as? UITableView {
                let tableViewInfo = """
                Number of Sections: \(tableView.numberOfSections)
                Number of Rows in Section 0: \(tableView.numberOfRows(inSection: 0))
                """

                additionalInfo += "\n\n- UITableView Info: \n\(tableViewInfo)\n"
            }

            // Additional UICollectionView information
            if let collectionView = view as? UICollectionView {
                let collectionViewInfo = """
                Number of Sections: \(collectionView.numberOfSections)
                Number of Items in Section 0: \(collectionView.numberOfItems(inSection: 0))
                """

                additionalInfo += "\n\n- UICollectionView Info: \n\(collectionViewInfo)\n"
            }

            // Additional UIScrollView information
            if let scrollView = view as? UIScrollView {
                let scrollViewInfo = """
                Content Size: \(scrollView.contentSize)
                Content Offset: \(scrollView.contentOffset)
                """

                additionalInfo += "\n\n- UIScrollView Info: \n\(scrollViewInfo)\n"
            }

            return String(
                format: """
                Class: %@
                Frame: (%.1f, %.1f, %.1f, %.1f)
                Alpha: %.2f
                Background Color: %@
                Tag: %d
                %@
                """,
                className,
                frame.origin.x,
                frame.origin.y,
                frame.size.width,
                frame.size.height,
                alpha,
                backgroundColor,
                tag,
                additionalInfo
            )
        }
    }

    private weak var view: UIView?

    /// Constructs a new `ViewElement`
    ///
    /// - Parameter view: The `UIView` to create the element for.
    @objc init(view: UIView) {
        self.view = view
    }
}

@MainActor
private func getViewController(view: UIView) -> UIViewController? {
    if let viewController = getNearestAncestorViewController(responder: view), viewController.viewIfLoaded == view {
        return viewController
    }
    return nil
}

@MainActor
private func drawView(_ view: UIView) -> CGImage? {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0 // Use 1.0 scale to avoid resolution issues
    format.opaque = false
    
    let renderer = UIGraphicsImageRenderer(size: view.bounds.size, format: format)
    let image = renderer.image { _ in
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }
    
    return image.cgImage
}

@MainActor
private func hideViewsOnTopOf(view: UIView, root: UIView, hiddenViews: inout [UIView]) -> Bool {
    if root == view {
        return true
    }
    var foundView = false
    for subview in root.subviews.reversed() {
        if hideViewsOnTopOf(view: view, root: subview, hiddenViews: &hiddenViews) {
            foundView = true
            break
        }
    }
    if !foundView {
        if !root.isHidden {
            hiddenViews.append(root)
        }
        root.isHidden = true
    }
    return foundView
}

@MainActor
private func snapshotVisualEffectBackdropView(_ view: UIView) -> CGImage? {
    guard let window = view.window else {
        return nil
    }
    var hiddenViews = [UIView]()
    defer {
        hiddenViews.forEach { $0.isHidden = false }
    }
    // UIVisualEffectView is a special case that cannot be snapshotted
    // the same way as any other view. From Apple docs:
    //
    //   Many effects require support from the window that hosts the
    //   UIVisualEffectView. Attempting to take a snapshot of only the
    //   UIVisualEffectView will result in a snapshot that does not
    //   contain the effect. To take a snapshot of a view hierarchy
    //   that contains a UIVisualEffectView, you must take a snapshot
    //   of the entire UIWindow or UIScreen that contains it.
    //
    // To snapshot this view, we traverse the view hierarchy starting
    // from the window and hide any views that are on top of the
    // _UIVisualEffectBackdropView so that it is visible in a snapshot
    // of the window. We then take a snapshot of the window and crop
    // it to the part that contains the backdrop view. This appears to
    // be the same technique that Xcode's own view debugger uses to
    // snapshot visual effect views.
    if hideViewsOnTopOf(view: view, root: window, hiddenViews: &hiddenViews) {
        let image = drawView(window)
        let cropRect = window.convert(view.bounds, from: view)
        return image?.cropping(to: cropRect)
    }
    return nil
}

@MainActor
private func snapshotView(_ view: UIView) -> CGImage? {
    // Handle visual effect views specially
    if let superview = view.superview, let _ = superview as? UIVisualEffectView,
       superview.subviews.first == view {
        return snapshotVisualEffectBackdropView(view)
    }

    // Hide subviews temporarily
    var subviewHidden = [Bool]()
    subviewHidden.reserveCapacity(view.subviews.count)
    for subview in view.subviews {
        subviewHidden.append(subview.isHidden)
        subview.isHidden = true
    }

    defer {
        // Restore subview visibility
        for (subview, isHidden) in zip(view.subviews, subviewHidden) {
            subview.isHidden = isHidden
        }
    }

    let viewSize = view.bounds.size
    let maxTextureSize: CGFloat = 8192

    // If view is within texture size limits, snapshot normally
    if viewSize.height <= maxTextureSize && viewSize.width <= maxTextureSize {
        return drawView(view)
    }

    // For oversized views, create a scaled version
    let scale = maxTextureSize / max(viewSize.width, viewSize.height)
    let scaledSize = CGSize(
        width: viewSize.width * scale,
        height: viewSize.height * scale
    )

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
    let image = renderer.image { context in
        context.cgContext.scaleBy(x: scale, y: scale)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }

    return image.cgImage
}

@MainActor
private func contentOffsetForView(_ view: UIView?) -> CGPoint {
    guard let scrollView = view?.superview as? UIScrollView else { return .zero }
    let contentOffset = scrollView.contentOffset
    return CGPoint(x: -contentOffset.x, y: -contentOffset.y)
}
