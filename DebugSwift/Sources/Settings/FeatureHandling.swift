//
//  FeatureHandling.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 24/01/24.
//

import CoreLocation
import UIKit

@MainActor
enum FeatureHandling {
    static var enabledBetaFeatures: [DebugSwiftBetaFeature] = []
    static func setup(
        only featuresToShow: [DebugSwiftFeature] = DebugSwiftFeature.allCases
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            MainActor.assumeIsolated {
                DebugSwift.App.shared.defaultControllers.removeAll(where: { !featuresToShow.contains($0.controllerType) })
                FloatViewManager.setup(TabBarController())
            }
        }
    }

    static func setup(
        hide features: [DebugSwiftFeature],
        disable methods: [DebugSwiftSwizzleFeature],
        enableBeta betaFeatures: [DebugSwiftBetaFeature] = []
    ) {
        setupBetaFeatures(betaFeatures)
        setupMethods(methods)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            MainActor.assumeIsolated {
                DebugSwift.App.shared.defaultControllers.removeAll(where: { features.contains($0.controllerType) })
                FloatViewManager.setup(TabBarController())
            }
        }
    }

    static func setupMethods(_ methodsToDisable: [DebugSwiftSwizzleFeature]) {
        DebugSwift.App.shared.disableMethods = methodsToDisable

        if !methodsToDisable.contains(.network) {
            enableNetwork()
        }

        if !methodsToDisable.contains(.webSocket) {
            enableWebSocket()
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
        
        if !methodsToDisable.contains(.swiftUIRender) {
            enableSwiftUIRender()
        }
    }

    private static func enableNetwork() {
        URLSessionConfiguration.swizzleMethods()
        NetworkHelper.shared.enable()
    }

    private static func enableWebSocket() {
        WebSocketMonitor.shared.enable()
    }

    private static func enableCrashManager() {
        StderrCapture.shared.startCapturing()
        StderrCapture.shared.syncData()

        CrashManager.shared.register()
    }

    private static func enableUIView() {
        Task {
            UIView.swizzleMethods()
            UIWindow.db_swizzleMethods()
        }
    }

    private static func enableLocation() {
        CLLocationManager.swizzleMethods()
    }

    private static func enableLeaksDetector() {
        Task {
            UIViewController.lvcdSwizzleLifecycleMethods()
        }
    }

    private static func enableConsole() {
        StdoutCapture.shared.startCapturing()
    }
    
    private static func enableSwiftUIRender() {
        // Only enable if beta features include SwiftUI render tracking
        guard enabledBetaFeatures.contains(.swiftUIRenderTracking) else { return }
        
        Task {
            UIView.enableSwiftUIRenderTracking()
        }
    }
    
    private static func setupBetaFeatures(_ betaFeatures: [DebugSwiftBetaFeature]) {
        enabledBetaFeatures = betaFeatures
    }
}
