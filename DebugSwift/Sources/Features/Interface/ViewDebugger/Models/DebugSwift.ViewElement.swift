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
            
            // Memory address
            additionalInfo += "\nMemory Address: \(Unmanaged.passUnretained(view).toOpaque())"
            
            // View state
            additionalInfo += "\n\n- View State:"
            additionalInfo += "\nIs Hidden: \(view.isHidden)"
            additionalInfo += "\nIs User Interaction Enabled: \(view.isUserInteractionEnabled)"
            additionalInfo += "\nClips To Bounds: \(view.clipsToBounds)"
            additionalInfo += "\nAutoresizing Mask: \(view.autoresizingMask.rawValue)"
            
            // Constraints info
            if !view.constraints.isEmpty {
                additionalInfo += "\n\n- Constraints:"
                additionalInfo += "\nNumber of Constraints: \(view.constraints.count)"
                additionalInfo += "\nTranslates Autoresizing Mask: \(view.translatesAutoresizingMaskIntoConstraints)"
            }

            // 1. Accessibility Information
            if view.isAccessibilityElement || view.accessibilityLabel != nil || view.accessibilityHint != nil {
                additionalInfo += "\n\n- Accessibility:"
                if let accessibilityLabel = view.accessibilityLabel {
                    additionalInfo += "\nLabel: \(accessibilityLabel)"
                }
                if let accessibilityHint = view.accessibilityHint {
                    additionalInfo += "\nHint: \(accessibilityHint)"
                }
                if let accessibilityIdentifier = view.accessibilityIdentifier {
                    additionalInfo += "\nIdentifier: \(accessibilityIdentifier)"
                }
                if view.isAccessibilityElement {
                    additionalInfo += "\nTraits: \(view.accessibilityTraits.rawValue)"
                }
            }

            // 2. Subviews and Hierarchy
            if !view.subviews.isEmpty {
                additionalInfo += "\n\n- Hierarchy:"
                additionalInfo += "\nSubviews Count: \(view.subviews.count)"
                let subviewsInfo = view.subviews.prefix(5).map { NSStringFromClass(type(of: $0)) }.joined(separator: ", ")
                additionalInfo += "\nSubviews: \(subviewsInfo)"
                if view.subviews.count > 5 {
                    additionalInfo += " ... and \(view.subviews.count - 5) more"
                }
            }
            
            // Superview info
            if let superview = view.superview {
                additionalInfo += "\nSuperview: \(NSStringFromClass(type(of: superview)))"
            }

            // 3. Gesture Recognizers
            if let gestureRecognizers = view.gestureRecognizers, !gestureRecognizers.isEmpty {
                additionalInfo += "\n\n- Gestures:"
                let gestureTypes = gestureRecognizers.map { NSStringFromClass(type(of: $0)) }.joined(separator: ", ")
                additionalInfo += "\n\(gestureTypes)"
            }

            // 4. Control State
            if let control = view as? UIControl {
                additionalInfo += "\n\n- Control:"
                additionalInfo += "\nState: \(control.state.rawValue)"
                additionalInfo += "\nIs Enabled: \(control.isEnabled)"
                additionalInfo += "\nIs Selected: \(control.isSelected)"
                additionalInfo += "\nIs Highlighted: \(control.isHighlighted)"
            }

            // 5. Content Mode
            let contentModeStrings = [
                "ScaleToFill", "ScaleAspectFit", "ScaleAspectFill", "Redraw",
                "Center", "Top", "Bottom", "Left", "Right",
                "TopLeft", "TopRight", "BottomLeft", "BottomRight"
            ]
            let contentModeIndex = Int(view.contentMode.rawValue)
            let contentModeString = contentModeIndex < contentModeStrings.count ? contentModeStrings[contentModeIndex] : "\(view.contentMode.rawValue)"
            additionalInfo += "\n\n- Layout:"
            additionalInfo += "\nContent Mode: \(contentModeString)"
            
            // Semantic content attribute
            let semanticStrings = ["Unspecified", "Playback", "Spatial", "ForceLeftToRight", "ForceRightToLeft"]
            let semanticIndex = Int(view.semanticContentAttribute.rawValue)
            additionalInfo += "\nSemantic: \(semanticIndex < semanticStrings.count ? semanticStrings[semanticIndex] : "\(view.semanticContentAttribute.rawValue)")"

            // 6. Layer Information
            let layer = view.layer
            additionalInfo += "\n\n- Layer Info:"
            additionalInfo += "\nBorder Width: \(layer.borderWidth)"
            additionalInfo += "\nBorder Color: \(layer.borderColor != nil ? "Set" : "None")"
            additionalInfo += "\nCorner Radius: \(layer.cornerRadius)"
            additionalInfo += "\nShadow Opacity: \(layer.shadowOpacity)"
            additionalInfo += "\nShadow Offset: \(layer.shadowOffset)"
            additionalInfo += "\nShadow Radius: \(layer.shadowRadius)"
            additionalInfo += "\nMask To Bounds: \(layer.masksToBounds)"
            additionalInfo += "\nOpacity: \(layer.opacity)"

            if let tintColor = view.tintColor?.hexString {
                additionalInfo += "\nTint Color: \(tintColor)"
            }

            // Check if the view is a UIButton
            if let button = view as? UIButton {
                additionalInfo += "\n\n- UIButton Info:"
                additionalInfo += "\nTitle: \(button.title(for: .normal) ?? "No title")"
                additionalInfo += "\nTitle Color: \((button.titleColor(for: .normal) ?? UIColor.black).hexString)"
                additionalInfo += "\nButton Type: \(button.buttonType.rawValue)"
                
                if let titleLabel = button.titleLabel {
                    additionalInfo += "\nFont: \(titleLabel.font.fontName) (\(titleLabel.font.pointSize)pt)"
                }
                
                if button.image(for: .normal) != nil {
                    additionalInfo += "\nHas Image: Yes"
                    if let imageSize = button.image(for: .normal)?.size {
                        additionalInfo += "\nImage Size: \(imageSize.width)x\(imageSize.height)"
                    }
                } else {
                    additionalInfo += "\nHas Image: No"
                }
                
                additionalInfo += "\nState: \(button.state.rawValue)"
            }

            // Check if the view is a UILabel
            if let label = view as? UILabel {
                additionalInfo += "\n\n- UILabel Info:"
                additionalInfo += "\nText: \(label.text ?? "No text")"
                additionalInfo += "\nFont: \(label.font.fontName) - \(label.font.pointSize)pt"
                additionalInfo += "\nText Color: \(label.textColor?.hexString ?? "No color")"
                additionalInfo += "\nText Alignment: \(label.textAlignment.rawValue)"
                additionalInfo += "\nNumber of Lines: \(label.numberOfLines)"
                additionalInfo += "\nLine Break Mode: \(label.lineBreakMode.rawValue)"
                additionalInfo += "\nAdjusts Font Size: \(label.adjustsFontSizeToFitWidth)"
            }

            if let imageView = view as? UIImageView {
                additionalInfo += "\n\n- UIImageView Info:"
                if let image = imageView.image {
                    additionalInfo += "\nImage Size: \(image.size.width)x\(image.size.height)"
                    additionalInfo += "\nScale: \(image.scale)x"
                } else {
                    additionalInfo += "\nImage: No image"
                }
                let contentModeStrings = ["ScaleToFill", "ScaleAspectFit", "ScaleAspectFill", "Redraw", "Center", "Top", "Bottom", "Left", "Right", "TopLeft", "TopRight", "BottomLeft", "BottomRight"]
                additionalInfo += "\nContent Mode: \(contentModeStrings[Int(imageView.contentMode.rawValue)])"
                additionalInfo += "\nIs Animating: \(imageView.isAnimating)"
                if imageView.isAnimating {
                    additionalInfo += "\nAnimation Images: \(imageView.animationImages?.count ?? 0)"
                    additionalInfo += "\nAnimation Duration: \(imageView.animationDuration)s"
                }
            }

            if let textView = view as? UITextView {
                additionalInfo += "\n\n- UITextView Info:"
                let textPreview = (textView.text ?? "No text").prefix(100)
                additionalInfo += "\nText: \(textPreview)\(textView.text?.count ?? 0 > 100 ? "..." : "")"
                additionalInfo += "\nFont: \(textView.font?.description ?? "No font")"
                additionalInfo += "\nText Color: \(textView.textColor?.hexString ?? "No color")"
                additionalInfo += "\nIs Editable: \(textView.isEditable)"
                additionalInfo += "\nIs Selectable: \(textView.isSelectable)"
                additionalInfo += "\nIs Scrollable: \(textView.isScrollEnabled)"
            }

            if let textField = view as? UITextField {
                additionalInfo += "\n\n- UITextField Info:"
                additionalInfo += "\nText: \(textField.text ?? "No text")"
                additionalInfo += "\nPlaceholder: \(textField.placeholder ?? "No placeholder")"
                additionalInfo += "\nFont: \(textField.font?.description ?? "No font")"
                additionalInfo += "\nText Color: \(textField.textColor?.hexString ?? "No color")"
                additionalInfo += "\nIs Editing: \(textField.isEditing)"
                additionalInfo += "\nIs Secure: \(textField.isSecureTextEntry)"
                additionalInfo += "\nKeyboard Type: \(textField.keyboardType.rawValue)"
                additionalInfo += "\nAutocorrection: \(textField.autocorrectionType.rawValue)"
            }

            // Additional UISearchBar information
            if let searchBar = view as? UISearchBar {
                additionalInfo += "\n\n- UISearchBar Info:"
                additionalInfo += "\nText: \(searchBar.text ?? "No text")"
                additionalInfo += "\nPlaceholder: \(searchBar.placeholder ?? "No placeholder")"
                additionalInfo += "\nBar Style: \(searchBar.barStyle.rawValue)"
                additionalInfo += "\nSearch Bar Style: \(searchBar.searchBarStyle.rawValue)"
            }

            // Additional UITableView information
            if let tableView = view as? UITableView {
                additionalInfo += "\n\n- UITableView Info:"
                additionalInfo += "\nNumber of Sections: \(tableView.numberOfSections)"
                if tableView.numberOfSections > 0 {
                    additionalInfo += "\nRows in Section 0: \(tableView.numberOfRows(inSection: 0))"
                }
                additionalInfo += "\nStyle: \(tableView.style.rawValue)"
                additionalInfo += "\nRow Height: \(tableView.rowHeight)"
                additionalInfo += "\nAllows Selection: \(tableView.allowsSelection)"
                additionalInfo += "\nSeparator Style: \(tableView.separatorStyle.rawValue)"
            }

            // Additional UICollectionView information
            if let collectionView = view as? UICollectionView {
                additionalInfo += "\n\n- UICollectionView Info:"
                additionalInfo += "\nNumber of Sections: \(collectionView.numberOfSections)"
                if collectionView.numberOfSections > 0 {
                    additionalInfo += "\nItems in Section 0: \(collectionView.numberOfItems(inSection: 0))"
                }
                additionalInfo += "\nAllows Selection: \(collectionView.allowsSelection)"
                additionalInfo += "\nAllows Multiple Selection: \(collectionView.allowsMultipleSelection)"
            }

            // Additional UIScrollView information
            if let scrollView = view as? UIScrollView {
                additionalInfo += "\n\n- UIScrollView Info:"
                additionalInfo += "\nContent Size: \(scrollView.contentSize.width)x\(scrollView.contentSize.height)"
                additionalInfo += "\nContent Offset: (\(scrollView.contentOffset.x), \(scrollView.contentOffset.y))"
                additionalInfo += "\nContent Inset: \(scrollView.contentInset)"
                additionalInfo += "\nIs Scrolling: \(scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating)"
                additionalInfo += "\nBounces: \(scrollView.bounces)"
                additionalInfo += "\nIs Paging Enabled: \(scrollView.isPagingEnabled)"
                additionalInfo += "\nShows Horizontal Indicator: \(scrollView.showsHorizontalScrollIndicator)"
                additionalInfo += "\nShows Vertical Indicator: \(scrollView.showsVerticalScrollIndicator)"
            }
            
            // UIStackView information
            if let stackView = view as? UIStackView {
                additionalInfo += "\n\n- UIStackView Info:"
                let axisStrings = ["Horizontal", "Vertical"]
                additionalInfo += "\nAxis: \(axisStrings[Int(stackView.axis.rawValue)])"
                let distributionStrings = ["Fill", "FillEqually", "FillProportionally", "EqualSpacing", "EqualCentering"]
                additionalInfo += "\nDistribution: \(distributionStrings[Int(stackView.distribution.rawValue)])"
                let alignmentStrings = ["Fill", "Leading", "Top", "FirstBaseline", "Center", "Trailing", "Bottom", "LastBaseline"]
                additionalInfo += "\nAlignment: \(alignmentStrings[Int(stackView.alignment.rawValue)])"
                additionalInfo += "\nSpacing: \(stackView.spacing)"
                additionalInfo += "\nArranged Subviews: \(stackView.arrangedSubviews.count)"
            }
            
            // UISwitch information
            if let switchControl = view as? UISwitch {
                additionalInfo += "\n\n- UISwitch Info:"
                additionalInfo += "\nIs On: \(switchControl.isOn)"
                if let onTintColor = switchControl.onTintColor {
                    additionalInfo += "\nOn Tint Color: \(onTintColor.hexString)"
                }
                if let thumbTintColor = switchControl.thumbTintColor {
                    additionalInfo += "\nThumb Tint Color: \(thumbTintColor.hexString)"
                }
            }
            
            // UISlider information
            if let slider = view as? UISlider {
                additionalInfo += "\n\n- UISlider Info:"
                additionalInfo += "\nValue: \(slider.value)"
                additionalInfo += "\nMinimum: \(slider.minimumValue)"
                additionalInfo += "\nMaximum: \(slider.maximumValue)"
                additionalInfo += "\nIs Continuous: \(slider.isContinuous)"
            }
            
            // UIProgressView information
            if let progressView = view as? UIProgressView {
                additionalInfo += "\n\n- UIProgressView Info:"
                additionalInfo += "\nProgress: \(progressView.progress)"
                additionalInfo += "\nStyle: \(progressView.progressViewStyle.rawValue)"
            }
            
            // UIActivityIndicatorView information
            if let activityIndicator = view as? UIActivityIndicatorView {
                additionalInfo += "\n\n- UIActivityIndicator Info:"
                additionalInfo += "\nIs Animating: \(activityIndicator.isAnimating)"
                additionalInfo += "\nHides When Stopped: \(activityIndicator.hidesWhenStopped)"
                additionalInfo += "\nStyle: \(activityIndicator.style.rawValue)"
            }
            
            // SwiftUI Hosting Controller detection
            if let hostingVC = getViewController(view: view),
               String(describing: type(of: hostingVC)).contains("HostingController") ||
               String(describing: type(of: hostingVC)).contains("HostingView") {
                additionalInfo += "\n\n- SwiftUI Info:"
                additionalInfo += "\nHosting Controller: \(String(describing: type(of: hostingVC)))"
                
                // Try to extract SwiftUI view information using reflection
                let swiftUIInfo = extractSwiftUIInfo(from: view, viewController: hostingVC)
                if !swiftUIInfo.isEmpty {
                    additionalInfo += "\n\(swiftUIInfo)"
                }
            }
            
            // Check if view itself is SwiftUI related
            let viewClassName = String(describing: type(of: view))
            if viewClassName.contains("SwiftUI") {
                additionalInfo += "\n\n- SwiftUI Component:"
                additionalInfo += "\nSwiftUI Type: \(viewClassName)"
                
                // Extract modifiers and properties using reflection
                let mirror = Mirror(reflecting: view)
                var swiftUIProperties: [String] = []
                
                for child in mirror.children {
                    if let label = child.label {
                        let value = String(describing: child.value)
                        // Filter out common system properties
                        if !label.hasPrefix("_") && value.count < 100 {
                            swiftUIProperties.append("\(label): \(value)")
                        }
                    }
                }
                
                if !swiftUIProperties.isEmpty {
                    additionalInfo += "\nProperties: \(swiftUIProperties.joined(separator: ", "))"
                }
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
private func extractSwiftUIInfo(from view: UIView, viewController: UIViewController) -> String {
    var info = ""
    
    // Try to get the root view from hosting controller
    let mirror = Mirror(reflecting: viewController)
    
    for child in mirror.children {
        if let label = child.label {
            // Look for rootView or similar properties
            if label.contains("rootView") || label.contains("content") {
                info += "\nRoot View Type: \(type(of: child.value))"
                
                // Inspect the SwiftUI view structure
                let viewMirror = Mirror(reflecting: child.value)
                var viewProperties: [String] = []
                
                for viewChild in viewMirror.children {
                    if let viewLabel = viewChild.label,
                       !viewLabel.hasPrefix("_"),
                       !viewLabel.contains("$__") {
                        let valueString = String(describing: viewChild.value)
                        if valueString.count < 50 {
                            viewProperties.append("\(viewLabel): \(valueString)")
                        }
                    }
                }
                
                if !viewProperties.isEmpty {
                    info += "\nView Properties:"
                    for prop in viewProperties.prefix(10) {
                        info += "\n  • \(prop)"
                    }
                    if viewProperties.count > 10 {
                        info += "\n  ... and \(viewProperties.count - 10) more"
                    }
                }
            }
        }
    }
    
    // Extract environment and modifier information
    let viewMirror = Mirror(reflecting: view)
    var modifiers: [String] = []
    
    for child in viewMirror.children {
        if let label = child.label {
            if label.contains("Modifier") || label.contains("Environment") {
                modifiers.append(label)
            }
        }
    }
    
    if !modifiers.isEmpty {
        info += "\nModifiers: \(modifiers.joined(separator: ", "))"
    }
    
    return info
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
