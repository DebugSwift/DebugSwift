//
//  DebugSwiftSettings.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

public struct DebugSwiftSettings {

    public static func setup() {
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.setup(TabBarController())
            NetworkHelper.shared.enable()
        }
    }

    public static func show() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.show()
        }
    }

    public static func hide() {
        FloatViewManager.remove()
    }
}
