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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: DSFloatChat.animationDuration) {
            WindowManager.showNavigationBar()
        }
    }

    private func configureTabBar() {
        let customControllers = DebugSwift.App.shared.customControllers?() ?? []
        let controllers = DebugSwift.App.shared.defaultControllers + customControllers

        viewControllers = controllers.map {
            UINavigationController(rootViewController: $0)
        }

        tabBar.tintColor = UIColor.white
        tabBar.unselectedItemTintColor = .gray
        tabBar.setBackgroundColor(color: UIColor.black)
        tabBar.addTopBorderWithColor(color: .gray, thickness: 0.3)
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true
        addRightBarButton(
            image: .named(
                "arrow.down.right.and.arrow.up.left",
                default: "Close"
            ),
            tintColor: UIColor.white
        ) { [weak self] in
            self?.closeButtonTapped()
        }
    }

    @objc private func closeButtonTapped() {
        WindowManager.removeDebugger()
    }
}
