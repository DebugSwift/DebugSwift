//
//  Performance.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class BaseController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    init(withNib: Bool) {
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

        setupTabBar()
        setupNavigation()
    }

}

fileprivate extension TabBarController {
    func setupTabBar() {
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

    func setupNavigation() {
        // Remove the default back button
        navigationItem.hidesBackButton = true

        let closeButton: UIBarButtonItem
        if #available(iOS 14.0, *) {
            closeButton = UIBarButtonItem(systemItem: .close)
            closeButton.target = self
            closeButton.action = #selector(closeButtonTapped)
        } else {
            // Add a custom "close" button
            closeButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeButtonTapped))
        }

        navigationItem.rightBarButtonItem = closeButton
    }

    @objc func closeButtonTapped() {
        // Handle close button tap
        // For example, you can dismiss the current view controller
        navigationController?.popViewController(animated: true)
    }
}

// Usage
let tabBarController = TabBarController()
// Present or set as the root view controller as needed
