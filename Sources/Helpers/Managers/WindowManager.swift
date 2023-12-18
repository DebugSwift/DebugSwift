//
//  WindowManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation

struct WindowManager {
    static var rootNavigation: UINavigationController? {
        window.rootViewController as? UINavigationController
    }

    static let window: CustomWindow = {
        let window: CustomWindow
        if #available(iOS 13.0, *),
           let scene = UIApplication.shared.keyWindow?.windowScene {
            window = CustomWindow(windowScene: scene)
        } else {
            window = CustomWindow(frame: UIScreen.main.bounds)
        }
        window.windowLevel = .alert + 1

        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.setBackgroundColor(color: .clear)
        window.rootViewController = navigation
        window.isHidden = false
        return window
    }()

    static func presentDebugger() {
        if let viewController = FloatViewManager.shared.floatViewController {
            // Prevent clicks
            UIApplication.shared.beginIgnoringInteractionEvents()
            WindowManager.rootNavigation?.pushViewController(
                viewController,
                animated: true
            )
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }

    static func removeDebugger() {
        removeNavigationBar()
        rootNavigation?.popViewController(animated: true)
    }

    static func showNavigationBar() {
        rootNavigation?.setBackgroundColor()
    }

    static func removeNavigationBar() {
        rootNavigation?.setBackgroundColor(color: .clear)
    }
}

final class CustomWindow: UIWindow {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let ballView = FloatViewManager.shared.ballView

        if
            !ballView.isShowing ||
            ballView.point(inside: convert(point, to: ballView), with: event) {
            return true
        }

        return false
    }
}
