//
//  LaunchTimeTracker.shared.swift
//  LaunchTimeTracker
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

class LaunchTimeTracker: @unchecked Sendable {
    
    private init() {}
    static let shared = LaunchTimeTracker()
    
    var launchStartTime: Double?

    // Uses process start time from sysctl to compute elapsed startup time.
    // Falls back to `nil` when the kernel query is unavailable.
    func measureAppStartUpTime() {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let result = sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        guard result == 0,
              size >= MemoryLayout<kinfo_proc>.stride else {
            launchStartTime = nil
            return
        }

        let startTime = kinfo.kp_proc.p_starttime
        let processStartTimeSeconds = TimeInterval(startTime.tv_sec) + TimeInterval(startTime.tv_usec) / 1_000_000
        let currentTimeSeconds = Date().timeIntervalSince1970
        let measuredStartupTime = currentTimeSeconds - processStartTimeSeconds

        // Ignore clearly invalid negative results.
        launchStartTime = measuredStartupTime >= 0 ? measuredStartupTime : nil
    }
}
