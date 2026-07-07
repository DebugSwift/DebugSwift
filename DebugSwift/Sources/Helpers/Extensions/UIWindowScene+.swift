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
