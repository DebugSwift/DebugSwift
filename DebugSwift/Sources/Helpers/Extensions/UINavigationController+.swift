//
//  UINavigationController+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation
import UIKit

extension UINavigationController {
    func setBackgroundColor(color: UIColor = Theme.shared.setupBackgroundColor()) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = color
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        } else {
            if color == .clear {
                navigationBar.setBackgroundImage(UIImage(), for: .default)
                navigationBar.shadowImage = UIImage()
                navigationBar.isTranslucent = true
                navigationBar.barTintColor = .clear
            } else {
                navigationBar.barTintColor = color
                navigationBar.setBackgroundImage(nil, for: .default)
                navigationBar.shadowImage = nil
                navigationBar.isTranslucent = false
            }
        }
    }
}

extension UITabBar {
    func setBackgroundColor(color: UIColor = Theme.shared.setupBackgroundColor()) {
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = color
            standardAppearance = appearance
            if #available(iOS 15.0, *) {
                scrollEdgeAppearance = appearance
            }
        } else {
            barTintColor = color
        }
    }
}
