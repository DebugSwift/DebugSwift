//
//  FeatureHandling.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 24/01/24.
//

import UIKit
import CoreLocation

final class FeatureHandling {
    static let shared = FeatureHandling()
    
    func allFeatureHandler() {
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
        URLSessionConfiguration.swizzleMethods()
        CLLocationManager.swizzleMethods()
        LogIntercepter.shared.start()
        
        NetworkHelper.shared.enable()
        
        CrashManager.register()
    }
    
    func selectedFeatureHandler(viewController: String?) {
        switch viewController {
        case "network-title":
            URLSessionConfiguration.swizzleMethods()
            NetworkHelper.shared.enable()
        case "":
            break
        default:
            allFeatureHandler()
        }
    }
    
    func hideFeatureByIndex(indexArr: [Int]?) {
        guard let indexArr = indexArr else { return DebugSwift.setup()}
        LocalizationManager.shared.loadBundle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            var featureHandler: String = ""
            let tabBar = TabBarController()
            guard let tabBarVC = tabBar.viewControllers else { return DebugSwift.setup()}
            for (idx,value) in indexArr.enumerated() {
                if value >= tabBarVC.count {
                    DebugSwift.setup()
                    return
                }
                let values = idx == .zero ? value : value - (1 * idx)
                tabBar.viewControllers?.remove(at: values)
            }
            tabBar.viewControllers?.forEach {
                featureHandler += $0.title ?? ""
            }
            FeatureHandling.shared.selectedFeatureHandler(viewController: featureHandler)
            FloatViewManager.setup(tabBar)
        }
        LaunchTimeTracker.measureAppStartUpTime()
    }
}

