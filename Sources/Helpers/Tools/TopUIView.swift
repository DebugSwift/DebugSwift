//
//  TopUIView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class TopLevelViewWrapper: UIView {
    private(set) var widgetWindow: UIWindow?

    func toggle(with newValue: Bool) {
        if newValue {
            showWidgetWindow()
        }

        UIView.animate(
            withDuration: 0.35,
            animations: {
                self.alpha = newValue ? 1.0 : 0.0
            }
        ) { _ in
            self.isHidden = !newValue
            if !newValue {
                self.removeWidgetWindow()
            }
        }
    }

    func showWidgetWindow() {
        if #available(iOS 13.0, *),
           let scene = UIApplication.shared.keyWindow?.windowScene {
            widgetWindow = UIWindow(windowScene: scene)
        } else {
            widgetWindow = UIWindow(frame: UIScreen.main.bounds)
        }

        // Create a UIWindow instance associated with the scene
        widgetWindow?.rootViewController = UIViewController()
        widgetWindow?.rootViewController?.view.addSubview(self)
        widgetWindow?.isHidden = false
        widgetWindow?.isUserInteractionEnabled = false
        // Animation
        alpha = 0.0
        UIView.animate(withDuration: 0.35) { self.alpha = 1.0 }
    }

    func removeWidgetWindow() {
        widgetWindow?.isHidden = true
        widgetWindow = nil
    }
}
