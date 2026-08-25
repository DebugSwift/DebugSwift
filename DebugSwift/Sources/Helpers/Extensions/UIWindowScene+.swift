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
    /// Swizzles `viewDidAppear(_:)` using IMP-replacement rather than
    /// `method_exchangeImplementations`.
    ///
    /// `method_exchangeImplementations` renames the original method to
    /// `db_viewDidAppear(_:)` and dispatches through that renamed selector.
    /// Third-party agents that instrument UIKit lifecycle methods (e.g. NewRelic)
    /// detect the renamed selector on core UIKit classes such as
    /// `UINavigationController` and throw `NRInvalidArgumentException`, crashing
    /// the host app when another swizzler (e.g. SFMCSDK) also wraps
    /// `viewDidAppear(_:)` and calls through the chain.
    ///
    /// IMP-replacement keeps `viewDidAppear(_:)` pointing at a valid
    /// implementation and never exposes `db_viewDidAppear(_:)` in the dispatch
    /// chain, so co-swizzlers and method scanners never see a renamed selector.
    /// The original implementation is captured at install time and invoked
    /// directly via its IMP, so install order relative to other swizzlers does
    /// not matter.
    static func db_swizzleViewDidAppear() {
        DispatchQueue.once(token: "debugswift.uiviewcontroller.db_swizzleViewDidAppear") {
            guard let originalMethod = class_getInstanceMethod(
                UIViewController.self,
                #selector(UIViewController.viewDidAppear(_:))
            ) else { return }

            db_originalViewDidAppearIMP = method_getImplementation(originalMethod)

            let swizzledIMP: @convention(block) (UIViewController, Bool) -> Void = { vc, animated in
                // Invoke the original implementation directly via its IMP with
                // the canonical selector, avoiding any dispatch through a
                // renamed selector.
                typealias ViewDidAppearIMP = @convention(c) (UIViewController, Selector, Bool) -> Void
                if let originalIMP = UIViewController.db_originalViewDidAppearIMP {
                    let castedIMP = unsafeBitCast(originalIMP, to: ViewDidAppearIMP.self)
                    castedIMP(vc, #selector(UIViewController.viewDidAppear(_:)), animated)
                }

                if #available(iOS 16.0, *) {
                    WindowManager.window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                } else {
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }

            method_setImplementation(originalMethod, imp_implementationWithBlock(swizzledIMP))
        }
    }

    /// Stored original `viewDidAppear(_:)` IMP, captured before swizzling.
    /// `nonisolated(unsafe)` because it is written exactly once (guarded by
    /// `DispatchQueue.once`) and only read afterward.
    nonisolated(unsafe) static var db_originalViewDidAppearIMP: IMP?
}
