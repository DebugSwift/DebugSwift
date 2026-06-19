//
//  AIStatus.swift
//  DebugSwift
//

#if DEBUG
import Foundation

public struct AIStatus: Codable, Sendable, Equatable {
    public let bridgeEnabled: Bool
    public let port: Int
    public let features: [String: FeatureState]
    public let device: DeviceInfo
    public let launchTimeMs: Double?

    public init(
        bridgeEnabled: Bool,
        port: Int,
        features: [String: FeatureState],
        device: DeviceInfo,
        launchTimeMs: Double?
    ) {
        self.bridgeEnabled = bridgeEnabled
        self.port = port
        self.features = features
        self.device = device
        self.launchTimeMs = launchTimeMs
    }
}

public struct FeatureState: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let options: [String: String]?

    public init(enabled: Bool, options: [String: String]? = nil) {
        self.enabled = enabled
        self.options = options
    }
}

public struct DeviceInfo: Codable, Sendable, Equatable {
    public let name: String
    public let model: String
    public let systemVersion: String
    public let bundleId: String
    public let appVersion: String?

    public init(
        name: String,
        model: String,
        systemVersion: String,
        bundleId: String,
        appVersion: String?
    ) {
        self.name = name
        self.model = model
        self.systemVersion = systemVersion
        self.bundleId = bundleId
        self.appVersion = appVersion
    }
}
#endif
