//
//  WindowManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation
import UIKit

@MainActor
enum WindowManager {
    nonisolated(unsafe) static var isSelectingWindow = false

    private static let floatingWindowLevel = UIWindow.Level.alert + 1
    private weak static var previousKeyWindow: UIWindow?

    static var rootNavigation: UINavigationController? {
        window.rootViewController as? UINavigationController
    }

    static let window: CustomWindow = {
        let window: CustomWindow
        if let scene = UIApplication.keyWindow?.windowScene {
            window = CustomWindow(windowScene: scene)
        } else {
            window = CustomWindow(frame: UIScreen.main.bounds)
        }
        window.windowLevel = floatingWindowLevel

        let navigation = OrientationForwardingNavigationController(rootViewController: UIViewController())
        navigation.interactivePopGestureRecognizer?.isEnabled = false
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
            window.isUserInteractionEnabled = false
            activateWindow()

            rootNavigation?.pushViewController(
                viewController,
                animated: true
            )
            window.isUserInteractionEnabled = true
        }
    }

    static func removeDebugger() {
        guard FloatViewManager.isShowingDebuggerView else {
            restorePreviousKeyWindow()
            return
        }

        FloatViewManager.isShowingDebuggerView = false
        removeNavigationBar()
        rootNavigation?.topViewController?.view.layer.mask = nil
        rootNavigation?.popViewController(animated: true)
        restorePreviousKeyWindow()
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
        activateWindow()

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

        let filteredWindows = UIWindowScene._windows.filter { window in
            String(describing: type(of: window)) != "UITextEffectsWindow"
                && window.windowLevel < UIWindow.Level.alert
        }

        guard filteredWindows.count > 1 else {
            InAppViewDebugger.presentForWindow(filteredWindows.first)
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
                InAppViewDebugger.presentForWindow(window)
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
        restorePreviousKeyWindow()
    }

    private static func activateWindow() {
        if UIApplication.keyWindow !== window {
            previousKeyWindow = UIApplication.keyWindow
        }

        previousKeyWindow?.endEditing(true)
        window.windowLevel = previousKeyWindow?.windowLevel ?? .normal
        window.makeKeyAndVisible()
    }

    private static func restorePreviousKeyWindow() {
        let fallbackWindow = window.windowScene?.windows.first {
            $0 !== window && !$0.isHidden && $0.windowLevel <= window.windowLevel
        }
        window.windowLevel = floatingWindowLevel
        (previousKeyWindow ?? fallbackWindow)?.makeKey()
        previousKeyWindow = nil
    }
}

final class CustomWindow: UIWindow {
    override func layoutSubviews() {
        super.layoutSubviews()

        for subview in subviews {
            if let ballView = subview as? FloatBallView {
                ballView.layer.position = FloatBallPositionHelper.restoreSavedPosition(in: self)
            } else if let bottomView = subview as? BottomFloatView {
                bottomView.frame = FloatBallPositionHelper.hiddenBottomFrame(in: self)
            }
        }
    }

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
