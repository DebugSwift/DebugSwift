//
//  UINavigation+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 22/01/25.
//

//
//  UINavigation+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 22/01/25.
//

import ObjectiveC
import UIKit

private var rightToLeftSwipeGestureRecognizerKey: Void?

// improve to get where dont have navigation
extension UINavigationController {
    static func swizzleMethods() {
        DispatchQueue.once(token: UUID().uuidString) {
            // Swizzle para cada inicializador
            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UINavigationController.init(navigationBarClass:toolbarClass:)),
                swizzledSelector: #selector(UINavigationController.swizzledInitWithNavigationBarClass(_:toolbarClass:))
            )

            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UINavigationController.init(rootViewController:)),
                swizzledSelector: #selector(UINavigationController.swizzledInitWithRootViewController(_:))
            )

            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UINavigationController.init(nibName:bundle:)),
                swizzledSelector: #selector(UINavigationController.swizzledInitWithNibName(_:bundle:))
            )

            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UINavigationController.init(coder:)),
                swizzledSelector: #selector(UINavigationController.swizzledInitWithCoder(_:))
            )
        }
    }

    // Swizzled methods for each initializer
    @objc private func swizzledInitWithNavigationBarClass(_ navigationBarClass: AnyClass?, toolbarClass: AnyClass?) -> UINavigationController {
        let viewController = swizzledInitWithNavigationBarClass(navigationBarClass, toolbarClass: toolbarClass)
        setupRightToLeftSwipeGesture()
        return viewController
    }

    @objc private func swizzledInitWithRootViewController(_ rootViewController: UIViewController) -> UINavigationController {
        let viewController = swizzledInitWithRootViewController(rootViewController)
        setupRightToLeftSwipeGesture()
        return viewController
    }

    @objc private func swizzledInitWithNibName(_ nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) -> UINavigationController {
        let viewController = swizzledInitWithNibName(nibNameOrNil, bundle: nibBundleOrNil)
        setupRightToLeftSwipeGesture()
        return viewController
    }

    @objc private func swizzledInitWithCoder(_ aDecoder: NSCoder) -> UINavigationController {
        let viewController = swizzledInitWithCoder(aDecoder)
        setupRightToLeftSwipeGesture()
        return viewController
    }

    private func setupRightToLeftSwipeGesture() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleRightToLeftSwipe(_:)))
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)

        objc_setAssociatedObject(self, &rightToLeftSwipeGestureRecognizerKey, gestureRecognizer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    @objc private func handleRightToLeftSwipe(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }

        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        if translation.x < 0 && abs(velocity.x) > abs(velocity.y) {
            handleRightToLeftNavigation()
        }
    }

    private func handleRightToLeftNavigation() {
        print("swipe right to left")

        HyperionSwift.shared.toogle()
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return true
    }
}
