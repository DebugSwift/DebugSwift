//
//  DebugSwift.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

public class DebugSwift {
    
    public init() {}
    
    @discardableResult
    @MainActor
    public func setup(
        hideFeatures features: [DebugSwiftFeature] = [],
        disable methods: [DebugSwiftSwizzleFeature] = [],
        enableBetaFeatures betaFeatures: [DebugSwiftBetaFeature] = []
    ) -> Self {
        FeatureHandling.setup(hide: features, disable: methods, enableBeta: betaFeatures)
        LaunchTimeTracker.shared.measureAppStartUpTime()

        return self
    }

    @discardableResult
    public func show() -> Self {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.show()
        }

        return self
    }

    @discardableResult
    @MainActor
    public func hide() -> Self {
        FloatViewManager.remove()
        return self
    }

    @discardableResult
    @MainActor
    public func toggle() -> Self {
        FloatViewManager.toggle()

        return self
    }
}

// MARK: - Namespace Enum to avoid module/class name conflicts
public enum DS {
    // This namespace enum prevents Swift module interface conflicts
    // between the module name 'DebugSwift' and the class name 'DebugSwift'
}

// MARK: - Backward Compatibility Extensions
extension DebugSwift {
    // Provide backward compatibility for existing public API
    public typealias Performance = DS.Performance
    public typealias PushNotification = DS.PushNotification
    public typealias APNSToken = DS.APNSToken
    public typealias App = DS.App
    public typealias Console = DS.Console
    public typealias Debugger = DS.Debugger
    public typealias HyperionSwift = DS.HyperionSwift
    public typealias Network = DS.Network
    public typealias SwiftUIRender = DS.SwiftUIRender
    public typealias WebSocket = DS.WebSocket
    public typealias WKWebView = DS.WKWebView
}
