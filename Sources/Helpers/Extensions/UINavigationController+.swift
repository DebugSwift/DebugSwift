//
//  UINavigationController+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation

extension UINavigationController {
    func setBackgroundColor(color: UIColor = .black) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = color
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        } else {
            navigationBar.barTintColor = color
        }
    }
}

extension UITabBar {
    func setBackgroundColor(color: UIColor = .black) {
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
