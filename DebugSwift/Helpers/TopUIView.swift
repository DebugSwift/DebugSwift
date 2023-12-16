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

        UIView.animate(withDuration: 0.35, animations: {
            self.alpha = newValue ? 1.0 : 0.0
        }) { (_) in
            self.isHidden = !newValue
            if !newValue {
                self.removeWidgetWindow()
            }
        }
    }

    func showWidgetWindow() {
        widgetWindow = UIWindow(frame: UIScreen.main.bounds)
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
