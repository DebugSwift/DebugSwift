//
//  DebugSwift.AI.swift
//  DebugSwift
//

#if DEBUG
import Foundation

public enum DebugSwiftAI {
  private nonisolated(unsafe) static var isBootstrapped = false

  public static var exportDirectory: URL {
    AIExportDirectory.url
  }

  public static func bootstrap() {
    _ = AIExportDirectory.url
    _ = AIExportDirectory.screenshotsURL
    isBootstrapped = true

    Debug.execute {
      Debug.print("[DebugSwift.AI] bootstrap — export dir:", exportDirectory.path)
    }
  }

  public static func setFeature(
    _ id: String,
    enabled: Bool,
    options: [String: Any]? = nil
  ) throws {
    guard isBootstrapped else {
      throw AIError.notBootstrapped
    }

    _ = (id, enabled, options)
  }

  public static func status() -> AIStatus {
    AIDeviceInfo.currentStatus()
  }

  public static func captureScreenshot(label: String? = nil) -> URL? {
    _ = label
    return nil
  }

  static func _resetBootstrapStateForTesting() {
    isBootstrapped = false
  }
}
#endif
