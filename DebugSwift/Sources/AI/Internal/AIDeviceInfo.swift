//
//  AIDeviceInfo.swift
//  DebugSwift
//

#if DEBUG
import UIKit

enum AIDeviceInfo {
  @MainActor
  static func makeDeviceInfo() -> DeviceInfo {
    DeviceInfo(
      name: UIDevice.current.name,
      model: UIDevice.current.modelName,
      systemVersion: UIDevice.current.systemVersion,
      bundleId: Bundle.main.bundleIdentifier ?? "",
      appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    )
  }

  static func currentStatus() -> AIStatus {
    let device = readDeviceInfo()
    let launchTimeMs = LaunchTimeTracker.shared.launchStartTime.map { $0 * 1_000 }

    return AIStatus(
      bridgeEnabled: false,
      port: AIConfiguration.port,
      features: [:],
      device: device,
      launchTimeMs: launchTimeMs
    )
  }

  private static func readDeviceInfo() -> DeviceInfo {
    if Thread.isMainThread {
      return MainActor.assumeIsolated { makeDeviceInfo() }
    }

    return DispatchQueue.main.sync {
      MainActor.assumeIsolated { makeDeviceInfo() }
    }
  }
}
#endif
