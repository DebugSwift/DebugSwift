//
//  Performace.FPSCalculator.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import QuartzCore
import UIKit

public class FPSCounter: NSObject {
    class DisplayLinkProxy: NSObject {
        @objc weak var parentCounter: FPSCounter?
        @objc func updateFromDisplayLink(_ displayLink: CADisplayLink) {
            parentCounter?.updateFromDisplayLink(displayLink)
        }
    }

    private let displayLink: CADisplayLink
    private let displayLinkProxy: DisplayLinkProxy

    override public init() {
        self.displayLinkProxy = DisplayLinkProxy()
        self.displayLink = CADisplayLink(
            target: displayLinkProxy,
            selector: #selector(DisplayLinkProxy.updateFromDisplayLink(_:))
        )

        super.init()

        displayLinkProxy.parentCounter = self
    }

    deinit {
        self.displayLink.invalidate()
    }

    /// Delay between FPS updates. Longer delays mean more averaged FPS numbers.
    @objc public var notificationDelay: TimeInterval = 1.0

    var fps: CGFloat = .zero

    // MARK: - Tracking

    private var runloop: RunLoop?
    private var mode: RunLoop.Mode?

    @objc public func startTracking(inRunLoop runloop: RunLoop = .main, mode: RunLoop.Mode = .common) {
        stopTracking()

        self.runloop = runloop
        self.mode = mode
        displayLink.add(to: runloop, forMode: mode)
    }

    @objc public func stopTracking() {
        guard let runloop, let mode else { return }

        displayLink.remove(from: runloop, forMode: mode)
        self.runloop = nil
        self.mode = nil
    }

    // MARK: - Handling Frame Updates

    private var lastNotificationTime: CFAbsoluteTime = 0.0
    private var numberOfFrames = 0

    private func updateFromDisplayLink(_: CADisplayLink) {
        if lastNotificationTime == 0.0 {
            lastNotificationTime = CFAbsoluteTimeGetCurrent()
            return
        }

        numberOfFrames += 1

        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - lastNotificationTime

        if elapsedTime >= notificationDelay {
            notifyUpdateForElapsedTime(elapsedTime)
            lastNotificationTime = 0.0
            numberOfFrames = 0
        }
    }

    private func notifyUpdateForElapsedTime(_ elapsedTime: CFAbsoluteTime) {
        fps = CGFloat(round(Double(numberOfFrames) / elapsedTime))
    }
}
