//
//  UserInfo.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import UIKit

public enum UserInfo {
    public struct Info {
        public let title: String
        public let detail: String
        
        public init(title: String, detail: String) {
            self.title = title
            self.detail = detail
        }
    }

    @MainActor
    static var infos: [Info] {
        [
            getAppVersionInfo(),
            getAppBuildInfo(),
            getBundleName(),
            getBundleId(),
            getScreenResolution(),
            getDeviceModelInfo(),
            getIOSVersionInfo(),
            getAPNSTokenInfo(),
            getMeasureAppStartUpTime(),
            getReachability()
        ].compactMap { $0 }
    }

    static func getAppVersionInfo() -> Info? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }

        return Info(
            title: "App Version:",
            detail: "\(version)"
        )
    }

    static func getAppBuildInfo() -> Info? {
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        else {
            return nil
        }

        return Info(
            title: "Build Version:",
            detail: "Build: \(build)"
        )
    }

    static func getBundleName() -> Info? {
        guard let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return nil
        }

        return Info(
            title: "Bundle Name:",
            detail: "\(bundleName)"
        )
    }

    static func getBundleId() -> Info? {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return nil
        }

        return Info(
            title: "Bundle ID:",
            detail: "\(bundleID)"
        )
    }

    @MainActor
    static func getScreenResolution() -> Info {
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

    @MainActor
    static func getDeviceModelInfo() -> Info {
        let deviceModel = UIDevice.current.modelName
        return Info(
            title: "Device Model:",
            detail: deviceModel
        )
    }

    @MainActor
    static func getIOSVersionInfo() -> Info {
        let iOSVersion = UIDevice.current.systemVersion
        return Info(
            title: "iOS Version:",
            detail: iOSVersion
        )
    }

    @MainActor
    static func getAPNSTokenInfo() -> Info {
        return APNSTokenManager.shared.getTokenInfo()
    }

    static func getMeasureAppStartUpTime() -> Info? {
        guard let launchStartTime = LaunchTimeTracker.shared.launchStartTime else { return nil }

        return Info(
            title: "Initialization Time:",
            detail: String(format: "%.4f", launchStartTime) + " (s)"
        )
    }

    static func getReachability() -> Info {
        Info(
            title: "Connection Type:",
            detail: ReachabilityManager.connection.description
        )
    }
}
