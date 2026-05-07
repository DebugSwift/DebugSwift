//
//  MeasurementWindowManager.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 01/01/25.
//

import Foundation
import UIKit

@MainActor
public enum MeasurementWindowManager {
    public static let measurementStateChangedNotification = Notification.Name("MeasurementStateChanged")
    
    public static var attachedWindow: UIWindow? {
        didSet {
            presentController.attachedWindow = attachedWindow
            let isEnabled = attachedWindow != nil

            window.isHidden = !isEnabled
            
            // Post notification when state changes
            NotificationCenter.default.post(
                name: measurementStateChangedNotification,
                object: nil,
                userInfo: ["isActive": isEnabled]
            )
        }
    }

    /// Gets the app's main window, excluding DebugSwift and system windows
    static var appMainWindow: UIWindow? {
        let allScenes = UIApplication.shared.connectedScenes
        let activeScenes = allScenes.filter { $0.activationState == .foregroundActive }
        let scenesToCheck = !activeScenes.isEmpty ? activeScenes : allScenes
        
        let appWindows = scenesToCheck
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .filter { window in
                // Filter out system windows and DebugSwift windows (alert level and above)
                let windowClassName = String(describing: type(of: window))
                return windowClassName != "UITextEffectsWindow"
                    && windowClassName != "UIRemoteKeyboardWindow" 
                    && window.windowLevel < UIWindow.Level.alert
            }
        
        // Prefer key window from app windows, otherwise return first available
        return appWindows.first(where: \.isKeyWindow) ?? appWindows.first
    }

    static var currentWindow: UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first(where: { $0.isKeyWindow })
    }

    private static var rootNavigation: UINavigationController? {
        let navigation = window.rootViewController as? UINavigationController
        return navigation
    }

    private static var presentController: CustomViewController {
        return rootNavigation!.topViewController! as! CustomViewController
    }

    private static let window: MeasurementWindow = {
        let window: MeasurementWindow
        
        if let scene = currentWindow?.windowScene {
            window = MeasurementWindow(windowScene: scene)
        } else {
            window = MeasurementWindow(frame: UIScreen.main.bounds)
        }

        let navigation = UINavigationController(rootViewController: CustomViewController())
        window.rootViewController = navigation
        window.isHidden = false

        return window
    }()
}

@MainActor
final class MeasurementWindow: UIWindow {
    override var description: String {
        MainActor.assumeIsolated {
            "MeasurementWindow is \(isHidden ? "hidden" : "visible")"
        }
    }

    override var windowLevel: UIWindow.Level {
        get {
            .alert + 1001
        }
        set {}
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if FloatViewManager.isShowingDebuggerView {
            return false
        }
        
        if MeasurementWindowManager.attachedWindow != nil {
            let ballView = FloatViewManager.shared.ballView
            if ballView.isShowing {
                let pointInScreen = convert(point, to: nil)
                let ballViewInScreen = ballView.convert(ballView.bounds, to: nil)
                
                if ballViewInScreen.contains(pointInScreen) {
                    DispatchQueue.main.async {
                        MeasurementWindowManager.attachedWindow = nil
                    }
                    return false
                }
            }
        }

        return true
    }
}

@MainActor
final class CustomViewController: UIViewController, MeasurementViewDelegate {
    var attachedWindow: UIWindow? {
        didSet {
            if attachedWindow != nil {
                view = MeasurementsView(delegate: self)
            }
        }
    }

    var contentView: MeasurementsView { view as! MeasurementsView }

    override func loadView() {
        super.loadView()
        view = MeasurementsView(delegate: self)
    }
}
