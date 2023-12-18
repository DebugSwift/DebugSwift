//
//  TabBarController.swift
//  LaunchTimeTracker
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBar()
        configureNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: DSFloatChat.animationDuration) {
            WindowManager.showNavigationBar()
        }
    }

    private func configureTabBar() {
        let controllers: [UIViewController] = [
            NetworkViewController(),
            PerformanceViewController(),
            InterfaceViewController(),
            ResourcesViewController(),
            AppViewController()
        ]

        viewControllers = controllers.map {
            UINavigationController(rootViewController: $0)
        }

        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .gray
        tabBar.setBackgroundColor(color: .black)
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true

        let closeButton: UIBarButtonItem
        if #available(iOS 13.0, *) {
            closeButton = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeButtonTapped)
            )
        } else {
            closeButton = UIBarButtonItem(
                title: "Close",
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )
            closeButton.tintColor = .white
        }

        navigationItem.rightBarButtonItem = closeButton
    }

    @objc private func closeButtonTapped() {
        WindowManager.removeDebugger()
    }
}
