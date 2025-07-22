//
//  StdoutCapture.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation
import UIKit

// MARK: - Global C-Compatible Function and State

/// Global state for C function pointer compatibility
nonisolated(unsafe) private var originalStdoutWriter: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int8>?, Int32) -> Int32)?
nonisolated(unsafe) private var stdoutBuffer = ""
nonisolated(unsafe) private var _isCapturing = false

/// Thread-safe locks for global state
private let bufferLock = NSLock()
private let stateLock = NSLock()
private let processingQueue = DispatchQueue(
    label: "com.debugswift.stdout.processing",
    qos: .utility,
    attributes: .concurrent
)

/// Thread-safe accessors for global state
private var isStdoutCapturing: Bool {
    get {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _isCapturing
    }
    set {
        stateLock.lock()
        defer { stateLock.unlock() }
        _isCapturing = newValue
    }
}

/// Global thread-safe buffered logging
private func logStdoutMessageGlobal(_ string: String) {
    guard isStdoutCapturing else { return }

    bufferLock.lock()
    defer { bufferLock.unlock() }

    stdoutBuffer += string

    // Process complete lines for better log organization
    let newlineSet = CharacterSet.newlines
    if let lastScalar = stdoutBuffer.unicodeScalars.last,
       newlineSet.contains(lastScalar) {

        let trimmed = stdoutBuffer.trimmingCharacters(in: newlineSet)
        if !trimmed.isEmpty {
            // Async file writing and console processing
            processingQueue.async {
                processCompleteLogLineGlobal(trimmed)
            }
        }
        stdoutBuffer = ""
    }
}

/// Global processing for complete log lines
private func processCompleteLogLineGlobal(_ line: String) {
    // File logging
    if let logUrl = StdoutCapture.shared.logUrl {
        do {
            try line.appendLineToURL(logUrl)
        } catch {
            // Silent failure for file writing
        }
    }

    // Console output processing
    appendConsoleOutputSafelyGlobal(line)
}

/// Global thread-safe console output with filtering
private func appendConsoleOutputSafelyGlobal(_ output: String) {
    guard !shouldIgnoreLogGlobal(output), shouldIncludeLogGlobal(output) else { return }

    // Direct append without additional async to prevent delays
    ConsoleOutput.shared.printAndNSLogOutput.append(output)
}

private func shouldIgnoreLogGlobal(_ log: String) -> Bool {
    DebugSwift.Console.shared.ignoredLogs.contains { log.contains($0) }
}

private func shouldIncludeLogGlobal(_ log: String) -> Bool {
    if DebugSwift.Console.shared.onlyLogs.isEmpty {
        return true
    }
    return DebugSwift.Console.shared.onlyLogs.contains { log.contains($0) }
}

// MARK: - C-Convention Handlers

/// Replacement for stdout _write function
@_cdecl("capturedStdoutWriter")
private func capturedStdoutWriter(
    fd: UnsafeMutableRawPointer?,
    buffer: UnsafePointer<Int8>?,
    size: Int32
) -> Int32 {
    // Call the original writer first
    let result = originalStdoutWriter?(fd, buffer, size) ?? size

    // Only capture if enabled and buffer valid
    guard isStdoutCapturing, let buf = buffer, size > 0 else {
        return result
    }

    // Safe string creation with size limit
    let safeSize = min(Int(size), 8192)
    let raw = UnsafeRawBufferPointer(start: buf, count: safeSize)
    guard let string = String(bytes: raw, encoding: .utf8), !string.isEmpty else {
        return result
    }

    // Async processing
    processingQueue.async {
        logStdoutMessageGlobal(string)
    }

    return result
}

/// Restorer function to reinstate the original writer
@_cdecl("standardStdoutWriter")
private func standardStdoutWriter(
    fd: UnsafeMutableRawPointer?,
    buffer: UnsafePointer<Int8>?,
    size: Int32
) -> Int32 {
    return originalStdoutWriter?(fd, buffer, size) ?? size
}

// MARK: - StdoutCapture Class

class StdoutCapture: @unchecked Sendable {
    static let shared = StdoutCapture()

    let logUrl: URL? = {
        if let path = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory,
            .userDomainMask,
            true
        ).first {
            let docs = URL(fileURLWithPath: path)
            return docs.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "app")-output.log")
        }
        return nil
    }()

    private init() {}

    // MARK: - Public API

    func startCapturing() {
        guard !isStdoutCapturing else { return }
        isStdoutCapturing = true

        Task {
            if let logUrl = logUrl {
                do {
                    let header = """
                    Start logger
                    DeviceID: \(await UIDevice.current.identifierForVendor?.uuidString ?? "none")
                    """
                    try header.write(to: logUrl, atomically: true, encoding: .utf8)
                } catch {
                    // Silent failure
                }
            }

            await MainActor.run {
                self.interceptStdoutWriter()
            }
        }
    }

    func stopCapturing() {
        guard isStdoutCapturing else { return }
        isStdoutCapturing = false

        // Restore original writer
        restoreOriginalStdoutWriter()

        // Clear buffer
        bufferLock.lock()
        stdoutBuffer = ""
        bufferLock.unlock()
    }

    // MARK: - Private Methods

    @MainActor
    private func interceptStdoutWriter() {
        // Store original writer only once
        if originalStdoutWriter == nil {
            originalStdoutWriter = stdout.pointee._write
        }
        // Redirect to our C-compatible handler
        stdout.pointee._write = capturedStdoutWriter
    }

    private func restoreOriginalStdoutWriter() {
        guard let original = originalStdoutWriter else { return }
        stdout.pointee._write = original
        originalStdoutWriter = nil
    }
}

// MARK: - File Utilities

extension String {
    fileprivate func appendLineToURL(_ fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL)
    }

    fileprivate func appendToURL(_ fileURL: URL) throws {
        if let data = data(using: .utf8) {
            try data.appendToURL(fileURL)
        }
    }
}

extension Data {
    fileprivate func appendToURL(_ fileURL: URL) throws {
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { handle.closeFile() }
            handle.seekToEndOfFile()
            handle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
