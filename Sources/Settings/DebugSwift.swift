//
//  DebugSwift.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

public enum DebugSwift {
    public static func setup() {
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
        URLSessionConfiguration.swizzleMethods()
        NetworkHelper.shared.enable()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.setup(TabBarController())
        }

        LaunchTimeTracker.measureAppStartUpTime()
    }

    public static func show() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.show()
        }
    }

    public static func hide() {
        FloatViewManager.remove()
    }

    public static var customInfo: (() -> [CustomData])?
}
