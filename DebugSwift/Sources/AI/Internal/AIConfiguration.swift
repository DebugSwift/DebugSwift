//
//  AIConfiguration.swift
//  DebugSwift
//

#if DEBUG
import Foundation

enum AIConfiguration {
  static let defaultPort = 9999

  static var isEnabled: Bool {
    ProcessInfo.processInfo.environment["DEBUGSWIFT_AI"] == "1"
      || ProcessInfo.processInfo.arguments.contains("-DebugSwiftAI")
  }

  static var port: Int {
    guard
      let portString = ProcessInfo.processInfo.environment["DEBUGSWIFT_AI_PORT"],
      let port = Int(portString)
    else {
      return defaultPort
    }
    return port
  }

  static var token: String? {
    let value = ProcessInfo.processInfo.environment["DEBUGSWIFT_AI_TOKEN"]
    guard let value, !value.isEmpty else { return nil }
    return value
  }
}
#endif
