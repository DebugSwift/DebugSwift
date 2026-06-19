//
//  AIExportDirectory.swift
//  DebugSwift
//

#if DEBUG
import Foundation

enum AIExportDirectory {
  private static let lock = NSLock()

  static var url: URL {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("debugswift-ai", isDirectory: true)
    createDirectoryIfNeeded(at: base)
    return base
  }

  static var screenshotsURL: URL {
    let screenshots = url.appendingPathComponent("screenshots", isDirectory: true)
    createDirectoryIfNeeded(at: screenshots)
    return screenshots
  }

  private static func createDirectoryIfNeeded(at url: URL) {
    lock.lock()
    defer { lock.unlock() }
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }
}
#endif
