//
//  DebugSwift.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit
import CoreLocation

public enum DebugSwift {
    public static func setup() {
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
        URLSessionConfiguration.swizzleMethods()
        CLLocationManager.swizzleMethods()
        LogIntercepter.shared.start()

        LocalizationManager.shared.loadBundle()
        NetworkHelper.shared.enable()

        if Crash.enable {
            CrashManager.register()
        }

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
}

extension DebugSwift {
    public enum Network {
        public static var ignoredURLs = [String]()
        public static var onlyURLs = [String]()
    }

    public enum App {
        public static var customInfo: (() -> [CustomData])?
    }

    public enum Console {
        public static var ignoredLogs = [String]()
        public static var onlyLogs = [String]()
    }

    public enum Debugger {
        @UserDefaultAccess(key: .crash, defaultValue: true)
        public static var enable: Bool
    }

    public enum Crash {
        @UserDefaultAccess(key: .crash, defaultValue: false)
        public static var enable: Bool {
            didSet {
                enable ? CrashManager.register() : CrashManager.unregister()
            }
        }
    }
}
