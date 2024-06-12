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
        only featuresToShow: [DebugSwiftMainFeature] = DebugSwiftMainFeature.allCases
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DebugSwift.App.defaultControllers.removeAll(where: { !featuresToShow.contains($0.controllerType) })
            FloatViewManager.setup(TabBarController())
        }
    }

    static func setup(
        hide features: [DebugSwiftMainFeature],
        disable methods: [DebugSwiftMethodFeature]
    ) {
        setupControllers(features)
        setupMethods(methods)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.setup(TabBarController())
        }
    }

    private static func setupControllers(_ featuresToHide: [DebugSwiftMainFeature]) {
        DebugSwift.App.defaultControllers.removeAll(where: { featuresToHide.contains($0.controllerType) })
    }

    private static func setupMethods(_ methodsToDisable: [DebugSwiftMethodFeature]) {
        DebugSwift.App.disableMethods = methodsToDisable

        if !methodsToDisable.contains(.network) && DebugSwift.App.defaultControllers.contains(where: { $0.controllerType == .network }) {
            enableNetwork()
        }

        if !methodsToDisable.contains(.swizzleLocation) {
            enableLocation()
        }

        if !methodsToDisable.contains(.swizzleViews) {
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

    private static  func enableNetwork() {
        URLSessionConfiguration.swizzleMethods()
        NetworkHelper.shared.enable()
    }

    private static func enableCrashManager() {
        StderrCapture.startCapturing()
        StderrCapture.syncData()

        CrashManager.register()
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
        StdoutCapture.startCapturing()
    }
}
