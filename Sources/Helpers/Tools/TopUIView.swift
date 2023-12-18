//
//  TopUIView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class TopLevelViewWrapper: UIView {
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
        WindowManager.window.rootViewController?.view.addSubview(self)
        alpha = .zero
        UIView.animate(withDuration: 0.35) { self.alpha = 1.0 }
    }

    func removeWidgetWindow() {
        self.removeFromSuperview()
    }
}
