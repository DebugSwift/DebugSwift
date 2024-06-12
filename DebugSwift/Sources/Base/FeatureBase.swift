//
//  FeatureBase.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

public protocol MainFeatureType {
    var controllerType: DebugSwiftMainFeature { get }
}

public enum DebugSwiftMainFeature: String, CaseIterable {
    case network
    case performance
    case interface
    case resources
    case app
}

public enum DebugSwiftMethodFeature: String, CaseIterable {
    case network
    case swizzleLocation
    case swizzleViews
    case crashManager
    case leaksDetector
    case console
}

@available(*, deprecated, renamed: "DebugSwiftMainFeature", message: "Use now DebugSwiftFeature")
public typealias DebugSwiftFeatures = DebugSwiftMainFeature
