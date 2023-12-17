//
//  UIApplication+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

extension UIApplication {
    class func topViewController(
        _ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}
