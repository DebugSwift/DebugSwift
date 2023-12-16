//
//  UIView+.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

private var UIViewShowsDebugBorderKey: UInt8 = 0
private var UIViewPreviousBorderColorKey: UInt8 = 1
private var UIViewPreviousBorderWidthKey: UInt8 = 2
private var UIViewDebugBorderColorKey: UInt8 = 3

extension UIView {

    // MARK: - ShowsDebugBorder property

    private var showsDebugBorder: Bool {
        get {
            return objc_getAssociatedObject(self, &UIViewShowsDebugBorderKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &UIViewShowsDebugBorderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - PreviousBorderColor property

    private var previousBorderColor: CGColor? {
        get {
            return (objc_getAssociatedObject(self, &UIViewPreviousBorderColorKey) as? UIColor)?.cgColor
        }
        set {
            if let color = newValue {
                objc_setAssociatedObject(self, &UIViewPreviousBorderColorKey, UIColor(cgColor: color), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    // MARK: - PreviousBorderWidth property

    private var previousBorderWidth: CGFloat {
        get {
            return objc_getAssociatedObject(self, &UIViewPreviousBorderWidthKey) as? CGFloat ?? 0.0
        }
        set {
            objc_setAssociatedObject(self, &UIViewPreviousBorderWidthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - DebugBorderColor property

    private var debugBorderColor: CGColor {
        get {
            if let color = objc_getAssociatedObject(self, &UIViewDebugBorderColorKey) as? UIColor {
                return color.cgColor
            } else {
                let color = UIColor.randomColor()
                objc_setAssociatedObject(self, &UIViewDebugBorderColorKey, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return color.cgColor
            }
        }
        set {
            objc_setAssociatedObject(self, &UIViewDebugBorderColorKey, UIColor(cgColor: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Method swizzling

    static func swizzleMethods() {
        DispatchQueue.once(token: NSUUID().uuidString) {
            // Swizzle init(coder:)
            swizzleMethod(self,
                          originalSelector: #selector(UIView.init(coder:)),
                          swizzledSelector: #selector(UIView.swizzledInitWithCoder(_:)))

            // Swizzle init(frame:)
            swizzleMethod(self,
                          originalSelector: #selector(UIView.init(frame:)),
                          swizzledSelector: #selector(UIView.swizzledInitWithFrame(_:)))

            // Swizzle dealloc
            swizzleMethod(self,
                          originalSelector: NSSelectorFromString("dealloc"),
                          swizzledSelector: #selector(UIView.swizzledDealloc))
        }
    }

    @objc private func swizzledInitWithCoder(_ aDecoder: NSCoder) -> UIView {
        let view = swizzledInitWithCoder(aDecoder)
        view.db_refreshDebugBorders()
        view.db_registerForNotifications()
        return view
    }

    @objc private func swizzledInitWithFrame(_ frame: CGRect) -> UIView {
        let view = swizzledInitWithFrame(frame)
        view.db_refreshDebugBorders()
        view.db_registerForNotifications()
        return view
    }

    @objc private func swizzledDealloc() {
        NotificationCenter.default.removeObserver(self)
        swizzledDealloc()
    }

    // MARK: - Colorized debug borders notifications

    private func db_registerForNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(db_handleColorizedDebugBordersChangedNotification(_:)),
            name: UserInterfaceToolkit.shared.colorizedViewBordersChangedNotification,
            object: nil
        )
    }

    @objc private func db_handleColorizedDebugBordersChangedNotification(_ notification: Notification) {
        db_refreshDebugBorders()
    }

    // MARK: - Handling debug borders

    private func db_refreshDebugBorders() {
        if UserInterfaceToolkit.shared.colorizedViewBordersEnabled {
            db_showDebugBorders()
        } else {
            db_hideDebugBorders()
        }
    }

    private func db_showDebugBorders() {
        guard !showsDebugBorder else { return }

        showsDebugBorder = true

        previousBorderWidth = layer.borderWidth
        previousBorderColor = layer.borderColor

        layer.borderColor = debugBorderColor
        layer.borderWidth = 1
    }

    private func db_hideDebugBorders() {
        guard showsDebugBorder else { return }

        showsDebugBorder = false

        layer.borderWidth = previousBorderWidth
        layer.borderColor = previousBorderColor
    }
}

private func swizzleMethod(_ classType: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
    let originalMethod = class_getInstanceMethod(classType, originalSelector)
    let swizzledMethod = class_getInstanceMethod(classType, swizzledSelector)

    let didAddMethod = class_addMethod(classType, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))

    if didAddMethod {
        class_replaceMethod(classType, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
    } else {
        method_exchangeImplementations(originalMethod!, swizzledMethod!)
    }
}
