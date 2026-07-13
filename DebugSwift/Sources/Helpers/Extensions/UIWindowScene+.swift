//
//  UIWindowScene+.swift
//  DebugSwift
//

import UIKit

extension UIWindowScene {
  @available(iOS 16.0, *)
  static func db_swizzleRequestGeometryUpdate() {
        DispatchQueue.once(token: "debugswift.uiwindowscene.db_swizzleRequestGeometryUpdate") {
            let originalSelector = #selector(UIWindowScene.requestGeometryUpdate(_:errorHandler:))
            let swizzledSelector = #selector(UIWindowScene.db_requestGeometryUpdate(_:errorHandler:))
            guard
                let originalMethod = class_getInstanceMethod(UIWindowScene.self, originalSelector),
                let swizzledMethod = class_getInstanceMethod(UIWindowScene.self, swizzledSelector)
            else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

  @available(iOS 16.0, *)
  @objc private func db_requestGeometryUpdate(
      _ preferences: UIWindowScene.GeometryPreferences,
        errorHandler: ((Error) -> Void)?
    ) {
        windows
            .filter { $0 is CustomWindow || $0 is MeasurementWindow }
            .forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }

        db_requestGeometryUpdate(preferences, errorHandler: errorHandler)
    }
}

extension UIViewController {
    static func db_swizzleViewDidAppear() {
        DispatchQueue.once(token: "debugswift.uiviewcontroller.db_swizzleViewDidAppear") {
            let original = #selector(UIViewController.viewDidAppear(_:))
            let swizzled = #selector(UIViewController.db_viewDidAppear(_:))
            guard
                let originalMethod = class_getInstanceMethod(UIViewController.self, original),
                let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
            else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc private func db_viewDidAppear(_ animated: Bool) {
        db_viewDidAppear(animated)
        if #available(iOS 16.0, *) {
            WindowManager.window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
