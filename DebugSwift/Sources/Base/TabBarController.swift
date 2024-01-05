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
        tabBar.addTopBorderWithColor(color: .gray, thickness: 0.3)
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true
        addRightBarButton(
            image: .named(
                getTabBarImageName(),
                default: "close".localized()
            ),
            tintColor: .white
        ) { [weak self] in
            self?.closeButtonTapped()
        }
    }

    @objc private func closeButtonTapped() {
        WindowManager.removeDebugger()
    }
}

// MARK: - Helper

extension TabBarController {
    /// Get `SF Symbols` image name for `TabBar` based on `iOS` version
    /// - Returns: image name
    private func getTabBarImageName() -> String {
        if #available(iOS 17.0, *) {
            return "arrow.up.right.and.arrow.down.left"
        }
        return "xmark.circle"
    }
}
