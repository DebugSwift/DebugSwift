//
//  UIView+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    // Associated object keys
    private static var showsDebugBorderKey: Void?
    private static var previousBorderColorKey: Void?
    private static var previousBorderWidthKey: Void?
    private static var debugBorderColorKey: Void?
    
    func simulateButtonTap(completion: (() -> Void)? = nil) {
        ImpactFeedback.generate()
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform.identity
            }) { _ in
                completion?()
            }
        }
    }

    func addTopBorderWithColor(color: UIColor, thickness: CGFloat = 1) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: thickness)
        layer.addSublayer(border)
    }

    // MARK: - ShowsDebugBorder property

    private var showsDebugBorder: Bool {
        get {
            objc_getAssociatedObject(self, &UIView.showsDebugBorderKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self, &UIView.showsDebugBorderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - PreviousBorderColor property

    private var previousBorderColor: CGColor? {
        get {
            (objc_getAssociatedObject(self, &UIView.previousBorderColorKey) as? UIColor)?.cgColor
        }
        set {
            if let color = newValue {
                objc_setAssociatedObject(
                    self, &UIView.previousBorderColorKey, UIColor(cgColor: color),
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }

    // MARK: - PreviousBorderWidth property

    private var previousBorderWidth: CGFloat {
        get {
            objc_getAssociatedObject(self, &UIView.previousBorderWidthKey) as? CGFloat ?? 0.0
        }
        set {
            objc_setAssociatedObject(
                self, &UIView.previousBorderWidthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - DebugBorderColor property

    private var debugBorderColor: CGColor {
        get {
            if let color = objc_getAssociatedObject(self, &UIView.debugBorderColorKey) as? UIColor {
                return color.cgColor
            }
            let color = UIColor.randomColor()
            objc_setAssociatedObject(
                self, &UIView.debugBorderColorKey, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return color.cgColor
        }
        set {
            objc_setAssociatedObject(
                self, &UIView.debugBorderColorKey, UIColor(cgColor: newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - Method swizzling

    static func swizzleMethods() {
        DispatchQueue.once(token: UUID().uuidString) {
            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UIView.init(coder:)),
                swizzledSelector: #selector(UIView.swizzledInitWithCoder(_:))
            )

            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UIView.init(frame:)),
                swizzledSelector: #selector(UIView.swizzledInitWithFrame(_:))
            )
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
            selector: #selector(changedNotification(_:)),
            name: UserInterfaceToolkit.notification,
            object: nil
        )
    }

    @objc private func changedNotification(
        _: Notification
    ) {
        db_refreshDebugBorders()
    }

    // MARK: - Handling debug borders

    private func db_refreshDebugBorders() {
        if UserInterfaceToolkit.colorizedViewBordersEnabled {
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
