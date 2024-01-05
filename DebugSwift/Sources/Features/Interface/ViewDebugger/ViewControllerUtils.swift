//
//  ViewUtils.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/4/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

func getNearestAncestorViewController(responder: UIResponder) -> UIViewController? {
    if let viewController = responder as? UIViewController {
        return viewController
    } else if let nextResponder = responder.next {
        return getNearestAncestorViewController(responder: nextResponder)
    }
    return nil
}

func topViewController(rootViewController: UIViewController?) -> UIViewController? {
    guard let rootViewController = rootViewController else {
        return nil
    }
    guard let presentedViewController = rootViewController.presentedViewController else {
        return rootViewController
    }
    
    if let navigationController = presentedViewController as? UINavigationController {
        return topViewController(rootViewController: navigationController.viewControllers.last)
    } else if let tabBarController = presentedViewController as? UITabBarController {
        return topViewController(rootViewController: tabBarController.selectedViewController)
    } else {
        return topViewController(rootViewController: presentedViewController)
    }
}
