//
//  Performance.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class BaseController: UIViewController {
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public init(withNib: Bool) {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let controllers = [
            NetworkViewController(), 
            PerformanceViewController(),
            ResourcesViewController(),
            InterfaceViewController(),
            AppViewController()
        ]

        viewControllers = controllers.map { 
            UINavigationController(rootViewController: $0)
        }

        tabBar.tintColor = .white
        tabBar.backgroundColor = .black
        tabBar.unselectedItemTintColor = .gray
    }
}

// Usage
let tabBarController = TabBarController()
// Present or set as the root view controller as needed
