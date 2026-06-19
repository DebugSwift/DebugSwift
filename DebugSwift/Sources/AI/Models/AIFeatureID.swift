//
//  AIFeatureID.swift
//  DebugSwift
//

#if DEBUG
import Foundation

public enum AIFeatureID {
  // Network
  public static let network = "network"
  public static let webSocket = "webSocket"
  public static let wkWebView = "wkWebView"

  // Performance
  public static let performance = "performance"
  public static let leaksDetector = "leaksDetector"
  public static let threadChecker = "threadChecker"

  // Interface
  public static let interfaceGrid = "interface.grid"
  public static let interfaceColorize = "interface.colorize"
  public static let interfaceTouchIndicators = "interface.touchIndicators"
  public static let swiftUIRender = "swiftUIRender"

  // App
  public static let console = "console"
  public static let oslog = "oslog"
  public static let crashManager = "crashManager"
  public static let pushNotifications = "pushNotifications"

  // Shell
  public static let floatBall = "floatBall"
}
#endif
