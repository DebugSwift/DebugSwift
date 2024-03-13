//
//  DebugSwift.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

public enum DebugSwift {
    public static func setup() {
        LocalizationManager.shared.loadBundle()
        FeatureHandling.shared.selectedFeatureHandler(viewController: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.setup(TabBarController())
        }

        LaunchTimeTracker.measureAppStartUpTime()
    }

    public static func setup(hideFeatures: [DebugSwiftFeatures]) {
        FeatureHandling.shared.hide(features: hideFeatures)
    }

    public static func show() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.show()
        }
    }

    public static func hide() {
        FloatViewManager.remove()
    }

    public static func toggle() {
        FloatViewManager.toggle()
    }

    public static func theme(appearance: Appearance) {
        Theme.shared.setAppearance(appearance: appearance)
    }

    @available(*, deprecated, renamed: "Debug.enable", message: "Use now Debug.enable")
    public static func toggleDebugger(_ enable: Bool) {
        Debug.enable = enable
    }
}

extension DebugSwift {
    public enum Network {
        public static var ignoredURLs = [String]()
        public static var onlyURLs = [String]()
    }

    public enum App {
        public static var customInfo: (() -> [CustomData])?
        public static var customAction: (() -> [CustomAction])?
        public static var customControllers: (() -> [UIViewController])?
    }

    public enum Console {
        public static var ignoredLogs = [String]()
        public static var onlyLogs = [String]()
    }

    public enum Debugger {
        /// /// Enable/Disable logs in Xcode console
        public static var logEnable: Bool {
            get {
                return Debug.enable
            } set {
                Debug.enable = newValue
            }
        }

        /// Enable/Disable `ImpactFeedback`
        public static var feedbackEnable: Bool {
            get {
                return ImpactFeedback.enable
            } set {
                ImpactFeedback.enable = newValue
            }
        }
    }
}
