//
//  App.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class AppViewModel: NSObject {
    var infos: [Info] {
        [
            getAppVersionInfo(),
            getAppBuildInfo(),
            getBundleName(),
            getBundleId(),
            getScreenResolution(),
            getDeviceModelInfo(),
            getIOSVersionInfo(),
            getMeasureAppStartUpTime()
        ].compactMap { $0 }
    }

    var customInfos: [CustomData] {
        DebugSwift.customInfo?() ?? []
    }

    func getAppVersionInfo() -> Info? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }

        return Info(
            title: "App Version:",
            detail: "\(version)"
        )
    }

    func getAppBuildInfo() -> Info? {
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        else {
            return nil
        }

        return Info(
            title: "Build Version:",
            detail: "Build: \(build)"
        )
    }

    func getBundleName() -> Info? {
        guard let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return nil
        }

        return Info(
            title: "Bundle Name:",
            detail: "\(bundleName)"
        )
    }

    func getBundleId() -> Info? {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return nil
        }

        return Info(
            title: "Bundle ID:",
            detail: "\(bundleID)"
        )
    }

    func getScreenResolution() -> Info {
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = screen.scale

        let screenWidth = bounds.size.width * scale
        let screenHeight = bounds.size.height * scale

        return .init(
            title: "Screen Resolution:",
            detail: "\(screenWidth) x \(screenHeight) points"
        )
    }

    func getDeviceModelInfo() -> Info {
        let deviceModel = UIDevice.current.model
        return Info(
            title: "Device Model:",
            detail: deviceModel
        )
    }

    func getIOSVersionInfo() -> Info {
        let iOSVersion = UIDevice.current.systemVersion
        return Info(
            title: "iOS Version:",
            detail: iOSVersion
        )
    }

    func getMeasureAppStartUpTime() -> Info? {
        guard let launchStartTime = LaunchTimeTracker.launchStartTime else { return nil }

        return Info(
            title: "Inicialization Time:",
            detail: String(format: "%.4lf%", launchStartTime) + " (s)"
        )
    }
}

extension AppViewModel {
    struct Info {
        let title: String
        let detail: String
    }
}
