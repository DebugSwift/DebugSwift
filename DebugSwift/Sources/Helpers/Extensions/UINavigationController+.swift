//
//  UINavigationController+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation
import UIKit

extension UINavigationController {
    func setBackgroundColor(color: UIColor = UIColor.black) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = color
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
}

extension UITabBar {
    func setBackgroundColor(color: UIColor = UIColor.black) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = color
        standardAppearance = appearance
        if #available(iOS 15.0, *) {
            scrollEdgeAppearance = appearance
        }
    }
}
