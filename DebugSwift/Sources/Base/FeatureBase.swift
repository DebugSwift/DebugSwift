//
//  FeatureBase.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

public protocol MainFeatureType {
    var controllerType: DebugSwiftFeature { get }
}

public enum DebugSwiftFeature: String, CaseIterable {
    case network
    case performance
    case interface
    case resources
    case app
}

public enum DebugSwiftSwizzleFeature: String, CaseIterable {
    case network
    case location
    case views
    case crashManager
    case leaksDetector
    case console
}

@available(*, deprecated, renamed: "DebugSwiftFeature", message: "Use now DebugSwiftFeature")
public typealias DebugSwiftFeatures = DebugSwiftFeature
