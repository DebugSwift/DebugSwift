//
//  HyperionSwift.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

public class HyperionSwift {
    private init() {}
    public static let shared = HyperionSwift()

    private lazy var menu = MenuViewController(delegate: self)
    private lazy var menuPresenter: SideMenuPresenting = SideMenuPresenter(
        menuViewControllerFactory: menu
    )
    private var isPreseting = false
    private weak var lastController: UIViewController?

    public func toogle() {
        isPreseting.toggle()

        // TODO: -  *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Application tried to present modally a view controller <DebugSwift.MenuViewController: 0x109c05a00> that is already being presented by <UINavigationController: 0x107041400>.'

        if let controller = topViewControoler() {
            setup(in: controller)
            present(from: controller)
        }
    }

    public func setup(in controller: UIViewController) {
        menuPresenter.setup(in: controller)
    }

    public func present(from controller: UIViewController) {
        menuPresenter.present(from: controller)
    }

    private func topViewControoler() -> UIViewController? {
        return UIApplication.shared.windows.first(where: \.isKeyWindow)?.rootViewController
    }
}

extension HyperionSwift: MenuDelegate {
    func didSelectMenuItem(_ menuItem: MenuItem) {
        switch menuItem {
        case .measurement:
            if isPreseting {
                activateMeasurement()
            } else {
                deactivateMeasurement()
            }
        }
    }

    private func activateMeasurement() {
        menu.dismiss(animated: true)
        MeasurementWindowManager.attachedWindow = UIWindow.keyWindow
    }

    private func deactivateMeasurement() {
        menu.dismiss(animated: true)
        MeasurementWindowManager.attachedWindow = nil
    }
}
