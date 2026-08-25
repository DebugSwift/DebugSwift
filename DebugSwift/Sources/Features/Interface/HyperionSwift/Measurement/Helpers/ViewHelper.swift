//
//  ViewHelper.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 01/01/25.
//

import UIKit

enum ViewHelper {
    /**
     * Retrieves a list of subviews that intersect a certain point.
     * @param view The view to find intersecting subviews in.
     * @param point The point at which an intersection of the views should be checked (in view's coordinate system).
     */
    @MainActor
    static func findSubviews(in view: UIView, intersectingPoint point: CGPoint) -> [UIView] {
        var potentialSelectionViews: [UIView] = []
        let subviews = view.subviews

        for subView in subviews.reversed() {
            if subView.alpha > 0, !subView.isHidden {
                // Convert point to subview's coordinate system for recursive search
                let pointInSubView = view.convert(point, to: subView)
                potentialSelectionViews.append(contentsOf: findSubviews(in: subView, intersectingPoint: pointInSubView))

                if Self.view(subView, surroundsPoint: point, relativeTo: view),
                   !shouldIgnoreForSelection(subView) {
                    potentialSelectionViews.append(subView)
                }
            }
        }

        return potentialSelectionViews
    }

    /**
     * Checks if the view surrounds the given point.
     * @param view The view to check.
     * @param point The point to check.
     * @param relativeTo The coordinate system to convert to.
     */
    @MainActor
    static func view(_ view: UIView, surroundsPoint point: CGPoint, relativeTo coordinateView: UIView) -> Bool {
        guard let superview = view.superview else { return false }
        // Convert to the specified coordinate system
        let viewRect = superview.convert(view.frame, to: coordinateView)

        return viewRect.origin.x <= point.x && (viewRect.size.width + viewRect.origin.x) >= point.x &&
            viewRect.origin.y <= point.y && (viewRect.size.height + viewRect.origin.y) >= point.y
    }

    /**
     * Returns a list of views that we do not want to show up as selectable views.
     */
    static func blacklistedViews() -> Set<String> {
        return ["_UINavigationControllerPaletteClippingView"]
    }

    /**
     * Excludes internal DebugSwift/Hyperion measurement views from being selected.
     */
    static func shouldIgnoreForSelection(_ view: UIView) -> Bool {
        let className = NSStringFromClass(type(of: view))

        if blacklistedViews().contains(className) {
            return true
        }

        return className.hasPrefix("DebugSwift.") || className.hasPrefix("HyperionSwift.")
    }
}
