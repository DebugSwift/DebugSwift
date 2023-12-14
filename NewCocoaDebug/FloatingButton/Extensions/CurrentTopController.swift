//
//  CurrentTopController.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 2023/12/12.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

extension NSObject {
    func currentViewController() -> UIViewController? {
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }

        if viewController.isKind(of: UINavigationController.self) {
            guard let viewController = (viewController as! UINavigationController).visibleViewController else {
                return nil
            }
            return viewController
        } else if viewController.isKind(of: UITabBarController.self) {
            guard let viewController = (viewController as! UITabBarController).selectedViewController else {
                return nil
            }
            return viewController
        }
       return nil
    }

    func currentNavigationController() -> UINavigationController? {
        return currentViewController()?.navigationController
    }

    func currentTabbarController() -> UITabBarController? {
        return currentViewController()?.tabBarController
    }
}
