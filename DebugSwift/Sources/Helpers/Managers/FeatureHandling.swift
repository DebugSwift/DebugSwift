//
//  FeatureHandling.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 24/01/24.
//

import CoreLocation
import UIKit

public enum DebugSwiftFeatures: String {
    case network = "network-title"
    case performance = "performance-title"
    case interface = "interface-title"
    case resources = "resources-title"
    case app = "app-title"

    var localized: String {
        rawValue.localized()
    }
}

final class FeatureHandling {
    static let shared = FeatureHandling()

    func allFeatureHandler() {
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
        URLSessionConfiguration.swizzleMethods()
        CLLocationManager.swizzleMethods()
        UIViewController.lvcdSwizzleLifecycleMethods()

        StdoutCapture.startCapturing()
        StderrCapture.startCapturing()
        StderrCapture.syncData()

        NetworkHelper.shared.enable()

        CrashManager.register()
    }

    func selectedFeatureHandler(viewController: String?) {
        switch viewController {
        case "network-title".localized():
            URLSessionConfiguration.swizzleMethods()
            NetworkHelper.shared.enable()
        case "":
            break
        default:
            allFeatureHandler()
        }
    }

    func getIndexFeature(titleVC: [UIViewController], debugSwiftFeature: String) -> Int {
        for (idx, value) in titleVC.enumerated() {
            if value.title?.contains(debugSwiftFeature) == true {
                return idx
            }
        }
        return -1
    }

    func hide(features: [DebugSwiftFeatures]?) {
        var featureHandler = ""
        guard let features else { return DebugSwift.setup() }

        features.forEach {
            featureHandler += $0.localized
        }
        FeatureHandling.shared.selectedFeatureHandler(viewController: featureHandler)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let tabBar = TabBarController()
            features.forEach {
                guard let tabBarVC = tabBar.viewControllers else { return DebugSwift.setup() }
                let index = self.getIndexFeature(titleVC: tabBarVC, debugSwiftFeature: $0.localized)
                if index != -1 {
                    tabBar.viewControllers?.remove(at: index)
                }
            }
            FloatViewManager.setup(tabBar)
        }
        LocalizationManager.shared.loadBundle()
        LaunchTimeTracker.measureAppStartUpTime()
    }
}
