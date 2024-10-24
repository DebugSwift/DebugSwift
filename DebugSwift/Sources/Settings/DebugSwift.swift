//
//  DebugSwift.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

public enum DebugSwift {

    @discardableResult
    public static func setup(
        hideFeatures features: [DebugSwiftFeature] = [],
        disable methods: [DebugSwiftSwizzleFeature] = []
    ) -> Self.Type {
        LocalizationManager.shared.loadBundle()
        FeatureHandling.setup(hide: features, disable: methods)
        LaunchTimeTracker.measureAppStartUpTime()

        return self
    }

    @discardableResult
    public static func show() -> Self.Type {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FloatViewManager.show()
        }

        return self
    }

    @discardableResult
    public static func hide() -> Self.Type {
        FloatViewManager.remove()
        return self
    }

    @discardableResult
    public static func toggle() -> Self.Type {
        FloatViewManager.toggle()

        return self
    }

    @discardableResult
    public static func theme(appearance: Appearance) -> Self.Type {
        Theme.shared.appearance = appearance

        return self
    }

    @discardableResult
    @available(*, deprecated, renamed: "Debug.enable", message: "Will be removed in next Version, use now Debug.enable")
    public static func toggleDebugger(_ enable: Bool) -> Self.Type {
        Debug.enable = enable

        return self
    }
}
