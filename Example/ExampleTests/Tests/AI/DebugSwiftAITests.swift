//
//  DebugSwiftAITests.swift
//  ExampleTests
//

import XCTest
@testable import DebugSwift

final class DebugSwiftAITests: XCTestCase {
  private let repeatCount = 3

  override func setUpWithError() throws {
    try super.setUpWithError()
    Debug.enable = true
    DebugSwiftAI._resetBootstrapStateForTesting()
  }

  override func tearDownWithError() throws {
    Debug.enable = false
    try super.tearDownWithError()
  }

  func testExportDirectoryResolvesUnderCaches() {
    for iteration in 0..<repeatCount {
      let exportDirectory = DebugSwiftAI.exportDirectory
      XCTAssertTrue(
        exportDirectory.path.contains("Caches"),
        "iteration \(iteration): export dir should live under Caches"
      )
      XCTAssertTrue(
        exportDirectory.lastPathComponent == "debugswift-ai",
        "iteration \(iteration): export dir name should be debugswift-ai"
      )
    }
  }

  func testExportDirectoryCreatesBaseFolderOnAccess() {
    for iteration in 0..<repeatCount {
      let base = DebugSwiftAI.exportDirectory

      var isDirectory: ObjCBool = false
      XCTAssertTrue(
        FileManager.default.fileExists(atPath: base.path, isDirectory: &isDirectory) && isDirectory.boolValue,
        "iteration \(iteration): base export directory should exist"
      )
    }
  }

  func testBootstrapCreatesScreenshotsFolder() {
    for iteration in 0..<repeatCount {
      DebugSwiftAI.bootstrap()

      let screenshots = DebugSwiftAI.exportDirectory
        .appendingPathComponent("screenshots", isDirectory: true)

      var isDirectory: ObjCBool = false
      XCTAssertTrue(
        FileManager.default.fileExists(atPath: screenshots.path, isDirectory: &isDirectory) && isDirectory.boolValue,
        "iteration \(iteration): screenshots directory should exist after bootstrap"
      )
    }
  }

  func testStatusReturnsStubbedBridgeStateAndDeviceInfo() {
    for iteration in 0..<repeatCount {
      let status = DebugSwiftAI.status()

      XCTAssertFalse(status.bridgeEnabled, "iteration \(iteration): bridge should be disabled in stub")
      XCTAssertEqual(status.port, AIConfiguration.defaultPort, "iteration \(iteration): default port")
      XCTAssertTrue(status.features.isEmpty, "iteration \(iteration): features should be empty")
      XCTAssertEqual(status.device.bundleId, Bundle.main.bundleIdentifier)
      XCTAssertEqual(
        status.device.appVersion,
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      )
      XCTAssertFalse(status.device.name.isEmpty, "iteration \(iteration): device name should be set")
      XCTAssertFalse(status.device.model.isEmpty, "iteration \(iteration): device model should be set")
      XCTAssertFalse(status.device.systemVersion.isEmpty, "iteration \(iteration): system version should be set")
    }
  }

  func testSetFeatureThrowsWhenNotBootstrapped() {
    for iteration in 0..<repeatCount {
      XCTAssertThrowsError(try DebugSwiftAI.setFeature(AIFeatureID.network, enabled: true)) { error in
        XCTAssertEqual(error as? AIError, .notBootstrapped, "iteration \(iteration)")
      }
    }
  }

  func testCaptureScreenshotStubReturnsNil() {
    for iteration in 0..<repeatCount {
      XCTAssertNil(DebugSwiftAI.captureScreenshot(label: "test-\(iteration)"))
    }
  }

  func testAIFeatureIDsAreStable() {
    for iteration in 0..<repeatCount {
      XCTAssertEqual(AIFeatureID.network, "network", "iteration \(iteration)")
      XCTAssertEqual(AIFeatureID.console, "console", "iteration \(iteration)")
      XCTAssertEqual(AIFeatureID.interfaceGrid, "interface.grid", "iteration \(iteration)")
    }
  }
}
