//
//  UIWindow+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

extension UIWindow {
    // MARK: - Constants

    private enum Constants {
        static let touchIndicatorViewMinAlpha: CGFloat = 0.6
        static var associatedTouchIndicators: UInt8 = 0
        static var associatedReusableTouchIndicators: UInt8 = 1
    }

    static var lastTouch: CGPoint?

    // MARK: - TouchIndicators property

    private var touchIndicators: NSMapTable<UITouch, TouchIndicatorView> {
        get {
            if let touchIndicators = objc_getAssociatedObject(self, &Constants.associatedTouchIndicators)
                as? NSMapTable<UITouch, TouchIndicatorView> {
                return touchIndicators
            } else {
                let touchIndicators = NSMapTable<UITouch, TouchIndicatorView>(
                    keyOptions: .weakMemory, valueOptions: .weakMemory
                )
                objc_setAssociatedObject(
                    self, &Constants.associatedTouchIndicators, touchIndicators,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
                return touchIndicators
            }
        }
        set {
            objc_setAssociatedObject(
                self, &Constants.associatedTouchIndicators, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - ReusableTouchIndicators property

    private var reusableTouchIndicators: NSMutableSet {
        get {
            if
                let reusableTouchIndicators = objc_getAssociatedObject(
                    self,
                    &Constants.associatedReusableTouchIndicators
                ) as? NSMutableSet
            {
                return reusableTouchIndicators
            } else {
                let reusableTouchIndicators = NSMutableSet()
                objc_setAssociatedObject(
                    self,
                    &Constants.associatedReusableTouchIndicators,
                    reusableTouchIndicators,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
                return reusableTouchIndicators
            }
        }
        set {
            objc_setAssociatedObject(
                self,
                &Constants.associatedReusableTouchIndicators,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - Method swizzling

    @objc class func db_swizzleMethods() {
        DispatchQueue.once(token: "debugswift.uiwindow.db_swizzleMethods") {
            let originalSelector = #selector(UIWindow.sendEvent(_:))
            let swizzledSelector = #selector(UIWindow.db_sendEvent(_:))
            guard let originalMethod = class_getInstanceMethod(self, originalSelector),
                  let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            else {
                return
            }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    // MARK: - Handling showing touches

    func setShowingTouchesEnabled(_ enabled: Bool) {
        if let enumerator = touchIndicators.objectEnumerator() {
            while let (_, touchIndicatorView) = enumerator.nextObject() as? (Any, TouchIndicatorView) {
                touchIndicatorView.isHidden = !enabled
            }
        }

        for case let touchIndicatorView as UIView in reusableTouchIndicators {
            touchIndicatorView.isHidden = !enabled
        }
    }

    func db_handleTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            db_handleTouch(touch)
        }
    }

    func db_handleTouch(_ touch: UITouch) {
        if touch.phase == .ended {
            Self.lastTouch = touch.location(in: nil)
        }

        guard UserInterfaceToolkit.shared.showingTouchesEnabled else { return }
        switch touch.phase {
        case .began:
            db_addTouchIndicator(with: touch)
        case .moved:
            db_moveTouchIndicator(with: touch)
        case .ended, .cancelled:
            db_removeTouchIndicator(with: touch)
        default:
            break
        }
    }

    func db_addTouchIndicator(with touch: UITouch) {
        guard let indicatorView = db_availableTouchIndicatorView() else { return }
        indicatorView.isHidden = !UserInterfaceToolkit.shared.showingTouchesEnabled
        touchIndicators.setObject(indicatorView, forKey: touch)
        addSubview(indicatorView)
        indicatorView.center = touch.location(in: self)
        db_handleTouchForce(touch)
    }

    func db_availableTouchIndicatorView() -> TouchIndicatorView? {
        if let indicatorView = reusableTouchIndicators.anyObject() as? TouchIndicatorView {
            reusableTouchIndicators.remove(indicatorView)
            return indicatorView
        } else {
            return TouchIndicatorView.indicatorView()
        }
    }

    func db_moveTouchIndicator(with touch: UITouch) {
        if let indicatorView = touchIndicators.object(forKey: touch) {
            indicatorView.center = touch.location(in: self)
            db_handleTouchForce(touch)
        }
    }

    func db_removeTouchIndicator(with touch: UITouch) {
        if let indicatorView = touchIndicators.object(forKey: touch) {
            indicatorView.removeFromSuperview()
            touchIndicators.removeObject(forKey: touch)
            reusableTouchIndicators.add(indicatorView)
        }
    }

    func db_handleTouchForce(_ touch: UITouch) {
        if let indicatorView = touchIndicators.object(forKey: touch) {
            var indicatorViewAlpha: CGFloat = 1.0

            if self.traitCollection.forceTouchCapability == UIForceTouchCapability.available {
                indicatorViewAlpha =
                Constants.touchIndicatorViewMinAlpha + (1.0 - Constants.touchIndicatorViewMinAlpha)
                * touch.force / touch.maximumPossibleForce
            }
            indicatorView.alpha = indicatorViewAlpha
        }
    }

    // MARK: - UIDebuggingInformationOverlay

    @objc func db_debuggingInformationOverlayInit() -> UIWindow {
        type(of: self).init()
    }

    @objc var state: UIGestureRecognizer.State {
        .ended
    }

    // MARK: - Swizzled Method

    @objc func db_sendEvent(_ event: UIEvent) {
        if event.type == .touches {
            db_handleTouches(event.allTouches!)
        }
        db_sendEvent(event)
    }

    static var keyWindow: UIWindow? {
        UIApplication.shared.windows.first(where: \.isKeyWindow)
    }

    var _snapshot: UIImage? {
        guard Thread.isMainThread else { return nil }
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, .zero)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    var _snapshotWithTouch: UIImage? {
        guard Thread.isMainThread else { return nil }

        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, .zero)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw the original snapshot
        layer.render(in: context)

        if let circleCenter = Self.lastTouch {
            // Draw a circle in the center of the image
            let circleRadius: CGFloat = 20

            context.setLineWidth(2)
            context.setStrokeColor(UIColor.red.cgColor)
            context.addArc(
                center: circleCenter,
                radius: circleRadius,
                startAngle: 0,
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )
            context.strokePath()
        }

        // Get the modified image
        let imageWithCircle = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithCircle
    }
}

// MARK: - DispatchQueue extension for once

extension DispatchQueue {
    private static var _onceTracker = [String]()

    class func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}
