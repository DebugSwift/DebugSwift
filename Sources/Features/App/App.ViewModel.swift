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
        guard
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
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

    func getMeasureAppStartUpTime() -> Info {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        let start_time = kinfo.kp_proc.p_starttime
        var time: timeval = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&time, nil)
        let currentTimeMilliseconds = Double(Int64(time.tv_sec) * 1000) + Double(time.tv_usec) / 1000.0
        let processTimeMilliseconds = Double(Int64(start_time.tv_sec) * 1000) + Double(start_time.tv_usec) / 1000.0

        let measuredTime = (currentTimeMilliseconds - processTimeMilliseconds) / 1000.0

        return Info(
            title: "Inicialization Time:",
            detail: String(format: "%.4lf%", measuredTime) + " (s)"
        )
    }
}

extension AppViewModel {
    struct Info {
        let title: String
        let detail: String
    }
}
