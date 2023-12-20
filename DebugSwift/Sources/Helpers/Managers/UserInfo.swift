//
//  UserInfo.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import UIKit

struct UserInfo {

    struct Info {
        let title: String
        let detail: String
    }

    static var infos: [Info] {
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

    static func getAppVersionInfo() -> Info? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }

        return Info(
            title: "app-version".localized(),
            detail: "\(version)"
        )
    }

    static func getAppBuildInfo() -> Info? {
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        else {
            return nil
        }

        return Info(
            title: "build-version".localized(),
            detail: "Build: \(build)"
        )
    }

    static func getBundleName() -> Info? {
        guard let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return nil
        }

        return Info(
            title: "bundle-name".localized(),
            detail: "\(bundleName)"
        )
    }

    static func getBundleId() -> Info? {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return nil
        }

        return Info(
            title: "bundle-id".localized(),
            detail: "\(bundleID)"
        )
    }

    static func getScreenResolution() -> Info {
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = screen.scale

        let screenWidth = bounds.size.width * scale
        let screenHeight = bounds.size.height * scale

        return .init(
            title: "screen-resolution".localized(),
            detail: "\(screenWidth) x \(screenHeight) points"
        )
    }

    static func getDeviceModelInfo() -> Info {
        let deviceModel = UIDevice.current.modelName
        return Info(
            title: "device-model".localized(),
            detail: deviceModel
        )
    }

    static func getIOSVersionInfo() -> Info {
        let iOSVersion = UIDevice.current.systemVersion
        return Info(
            title: "ios-version".localized(),
            detail: iOSVersion
        )
    }

    static func getMeasureAppStartUpTime() -> Info? {
        guard let launchStartTime = LaunchTimeTracker.launchStartTime else { return nil }

        return Info(
            title: "inicialization-time".localized(),
            detail: String(format: "%.4lf%", launchStartTime) + " (s)"
        )
    }
}
