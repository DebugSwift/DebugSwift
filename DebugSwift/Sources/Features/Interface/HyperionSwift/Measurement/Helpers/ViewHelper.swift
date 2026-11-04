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
        // 隐藏祖先、调试浮层及被父视图裁剪的区域，不应参与测量选取。
        guard !view.isHidden, view.alpha > 0.01,
              !isDebugOverlay(view),
              !view.clipsToBounds || view.bounds.contains(point) else {
            return []
        }

        var potentialSelectionViews: [UIView] = []

        for subView in view.subviews.reversed() {
            guard !subView.isHidden, subView.alpha > 0.01,
                  !isDebugOverlay(subView) else { continue }

            let pointInSubView = view.convert(point, to: subView)
            // 保留对非交互 Label、图片及未裁剪的越界子视图的检查能力。
            potentialSelectionViews.append(contentsOf: findSubviews(in: subView, intersectingPoint: pointInSubView))

            guard subView.bounds.contains(pointInSubView), !shouldIgnoreForSelection(subView) else { continue }
            // 系统浮动导航容器可能占满整屏，但在空白处主动让点击穿透。
            // 忽略这种容器自身，避免它挡住下方业务控件的测量；仍允许选取其可见子视图。
            guard !subView.isUserInteractionEnabled || subView.hitTest(pointInSubView, with: nil) != nil else { continue }
            potentialSelectionViews.append(subView)
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
        guard view.superview != nil else { return false }
        // 转换触点而非 frame 的外接矩形，兼容旋转、缩放和滚动后的 bounds。
        return view.bounds.contains(view.convert(point, from: coordinateView))
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

        return isDebugOverlay(view)
    }

    /// 调试覆盖层整棵子树均需排除；系统黑名单容器仍可继续检查其业务子控件。
    private static func isDebugOverlay(_ view: UIView) -> Bool {
        let className = NSStringFromClass(type(of: view))
        return className.hasPrefix("DebugSwift.") || className.hasPrefix("HyperionSwift.")
    }
}
