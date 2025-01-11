//
//  WindowManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation
import UIKit

enum WindowManager {
    static var isSelectingWindow = false
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
        window.windowLevel = .alert + 2

        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.setBackgroundColor(color: .clear)
        window.rootViewController = navigation
        window.isHidden = false
        return window
    }()

    static func presentDebugger() {
        guard !FloatViewManager.isShowingDebuggerView else { return }
        FloatViewManager.isShowingDebuggerView = true
        if let viewController = FloatViewManager.shared.floatViewController {
            // Prevent clicks
            UIApplication.shared.beginIgnoringInteractionEvents()
            // Remove keyboard, if opened.
            UIWindow.keyWindow?.endEditing(true)

            rootNavigation?.pushViewController(
                viewController,
                animated: true
            )
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }

    static func removeDebugger() {
        FloatViewManager.isShowingDebuggerView = false
        removeNavigationBar()
        rootNavigation?.popViewController(animated: true)
    }

    static func showNavigationBar() {
        rootNavigation?.setBackgroundColor()
    }

    static func removeNavigationBar() {
        rootNavigation?.setBackgroundColor(color: .clear)
    }

    static func presentViewDebugger() {
        guard !FloatViewManager.isShowingDebuggerView else { return }
        FloatViewManager.isShowingDebuggerView = true

        presentInWindow { window in
            HyperionSwift.present(in: window)
        }
    }

    private static func presentInWindow(completion: @escaping ((UIWindow) -> Void)) {
        let alertController = UIAlertController(
            title: "Select a Window",
            message: nil,
            preferredStyle: .actionSheet
        )

        alertController.popoverPresentationController?.sourceView = WindowManager.rootNavigation?.view

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = FloatViewManager.shared.ballView
            popoverController.sourceRect = FloatViewManager.shared.ballView.bounds
        }

        let filteredWindows = UIApplication.shared.windows.filter { window in
            String(describing: type(of: window)) != "UITextEffectsWindow"
                && window.windowLevel < UIWindow.Level.alert
        }

        guard filteredWindows.count > 1 else {
            completion(filteredWindows.first!)
            return
        }

        // Add an action for each window
        for window in filteredWindows {
            let className = NSStringFromClass(type(of: window))
            let moduleName = Bundle(for: type(of: window)).bundleIdentifier ?? "Unknown Module"

            let actionTitle = "\(className) - \(moduleName)"
            let action = UIAlertAction(title: actionTitle, style: .default) { _ in
                // Handle the selected window here
                isSelectingWindow = false
                completion(window)
            }
            alertController.addAction(action)
        }

        // Add a cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            isSelectingWindow = false
            removeViewDebugger()
        }
        alertController.addAction(cancelAction)

        // Present the UIAlertController
        isSelectingWindow = true
        rootNavigation?.present(alertController, animated: true)
    }

    static func removeViewDebugger() {
        FloatViewManager.isShowingDebuggerView = false
        rootNavigation?.dismiss(animated: true)
    }
}

final class CustomWindow: UIWindow {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if WindowManager.isSelectingWindow { return true }

        let ballView = FloatViewManager.shared.ballView
        if
            ballView.point(inside: convert(point, to: ballView), with: event) ||
            FloatViewManager.isShowingDebuggerView {
            return true
        }

        return false
    }
}
