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
     * @param view The view to find intersecting subviews.
     * @param point The point at which an intersection of the views should be checked.
     */
    static func findSubviews(in view: UIView, intersectingPoint point: CGPoint) -> [UIView] {
        var potentialSelectionViews: [UIView] = []
        let subviews = view.subviews
        let blackList = blacklistedViews()

        for subView in subviews.reversed() {
            if subView.alpha > 0, !subView.isHidden {
                potentialSelectionViews.append(contentsOf: findSubviews(in: subView, intersectingPoint: point))

                if Self.view(subView, surroundsPoint: point), !blackList.contains(NSStringFromClass(type(of: subView))) {
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
     */
    static func view(_ view: UIView, surroundsPoint point: CGPoint) -> Bool {
        guard let superview = view.superview else { return false }
        let viewRect = superview.convert(view.frame, to: MeasurementWindowManager.currentWindow)

        return viewRect.origin.x <= point.x && (viewRect.size.width + viewRect.origin.x) >= point.x &&
            viewRect.origin.y <= point.y && (viewRect.size.height + viewRect.origin.y) >= point.y
    }

    /**
     * Returns a list of views that we do not want to show up as selectable views.
     */
    static func blacklistedViews() -> Set<String> {
        return ["_UINavigationControllerPaletteClippingView"] // TODO: - Block touch in same module
    }
}
