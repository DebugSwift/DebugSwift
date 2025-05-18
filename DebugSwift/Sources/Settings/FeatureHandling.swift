//
//  FeatureHandling.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 24/01/24.
//

import CoreLocation
import UIKit

enum FeatureHandling {
    static func setup(
        only featuresToShow: [DebugSwiftFeature] = DebugSwiftFeature.allCases
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DebugSwift.App.shared.defaultControllers.removeAll(where: { !featuresToShow.contains($0.controllerType) })
            FloatViewManager.setup(TabBarController())
        }
    }

    static func setup(
        hide features: [DebugSwiftFeature],
        disable methods: [DebugSwiftSwizzleFeature]
    ) {
        setupControllers(features)
        setupMethods(methods)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.setup(TabBarController())
        }
    }

    private static func setupControllers(_ featuresToHide: [DebugSwiftFeature]) {
        DebugSwift.App.shared.defaultControllers.removeAll(where: { featuresToHide.contains($0.controllerType) })
    }

    private static func setupMethods(_ methodsToDisable: [DebugSwiftSwizzleFeature]) {
        DebugSwift.App.shared.disableMethods = methodsToDisable

        if !methodsToDisable.contains(.network) {
            enableNetwork()
        }

        if !methodsToDisable.contains(.location) {
            enableLocation()
        }

        if !methodsToDisable.contains(.views) {
            enableUIView()
        }

        if !methodsToDisable.contains(.crashManager) {
            enableCrashManager()
        }

        if !methodsToDisable.contains(.leaksDetector) {
            enableLeaksDetector()
        }

        if !methodsToDisable.contains(.console) {
            enableConsole()
        }
    }

    private static func enableNetwork() {
        URLSessionConfiguration.swizzleMethods()
        NetworkHelper.shared.enable()
    }

    private static func enableCrashManager() {
        StderrCapture.shared.startCapturing()
        StderrCapture.shared.syncData()

        CrashManager.shared.register()
    }

    private static func enableUIView() {
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
    }

    private static func enableLocation() {
        CLLocationManager.swizzleMethods()
    }

    private static func enableLeaksDetector() {
        UIViewController.lvcdSwizzleLifecycleMethods()
    }

    private static func enableConsole() {
        StdoutCapture.shared.startCapturing()
    }
}
