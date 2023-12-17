//
//  Debug.swift
//  LaunchTimeTracker
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

class LaunchTimeTracker {
    static var launchStartTime: Date?

    class func startTracking() {
        launchStartTime = Date()
    }

    class func printLaunchTime() {
        guard let launchStartTime = launchStartTime else {
            return
        }

        let launchTime = Date().timeIntervalSince(launchStartTime)
        print("Tempo de lançamento: \(launchTime) segundos")
    }
}
