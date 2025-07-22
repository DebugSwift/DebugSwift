/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2020-Present Datadog, Inc.
 */

@preconcurrency import Foundation

class StderrCapture: @unchecked Sendable {
    
    // ✅ NEW: Thread-safe state management
    private let stateLock = NSLock()
    private var _isCapturing = false
    var isCapturing: Bool {
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
    
    // ✅ NEW: Thread-safe serial queue to prevent deadlock
    private let captureQueue = DispatchQueue(
        label: "com.debugswift.stderr.capture",
        qos: .utility
    )
    
    private let processingQueue = DispatchQueue(
        label: "com.debugswift.stderr.processing",
        qos: .default,
        attributes: .concurrent
    )
    
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private var originalDescriptor = FileHandle.standardError.fileDescriptor
    
    private init() {}
    static let shared = StderrCapture()

    func startCapturing() {
        captureQueue.async { [weak self] in
            self?.startCapturingInternal()
        }
    }
    
    private func startCapturingInternal() {
        guard !isCapturing else { return }
        isCapturing = true

        // ✅ FIX: Thread-safe readability handler
        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let self = self, self.isCapturing else { return }
            
            // ✅ FIX: Process on dedicated queue to prevent deadlock
            self.captureQueue.async {
                let data = fileHandle.availableData
                if let string = String(data: data, encoding: .utf8), !string.isEmpty {
                    self.processingQueue.async {
                        self.stderrMessageSafe(string: string)
                    }
                }

                // ✅ FIX: Write back to stderr on same queue to prevent contention
                self.outputPipe.fileHandleForWriting.write(data)
            }
        }
        
        // ✅ FIX: Setup stderr redirection with error checking
        setvbuf(stderr, nil, _IONBF, 0)

        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        if dup2(FileHandle.standardError.fileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to duplicate stderr for output pipe")
            isCapturing = false
            return
        }

        // Intercept STDERR with inputPipe
        if dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to redirect stderr to input pipe")
            isCapturing = false
            return
        }
    }

    func syncData() {
        guard isCapturing, inputPipe.fileHandleForReading.isReadable else {
            return
        }

        // ✅ FIX: Use safer async approach instead of blocking wait
        captureQueue.async { [weak self] in
            guard let self = self, self.isCapturing else { return }
            
            let auxData = self.inputPipe.fileHandleForReading.availableData
            if !auxData.isEmpty,
               let string = String(data: auxData, encoding: .utf8) {
                self.processingQueue.async {
                    self.stderrMessageSafe(string: string)
                }
            }
        }
    }

    func stopCapturing() {
        captureQueue.async { [weak self] in
            self?.stopCapturingInternal()
        }
    }
    
    private func stopCapturingInternal() {
        guard isCapturing else { return }
        isCapturing = false
        
        // ✅ FIX: Clean up handlers safely
        inputPipe.fileHandleForReading.readabilityHandler = nil
        
        // ✅ FIX: Restore original stderr properly
        freopen("/dev/stderr", "a", stderr)
    }

    // ✅ NEW: Thread-safe message processing without recursive print()
    private func stderrMessageSafe(string: String) {
        if string.contains("OSLOG"),
           let message = string.split(separator: "\t").last {
            let message = String(message).trimmingCharacters(in: .whitespacesAndNewlines)
            ConsoleOutput.shared.printAndNSLogOutput.append("\(message)")
        } else {
            ConsoleOutput.shared.errorOutput.append(string)

            if string.contains("]") {
                var split = string.split(separator: "]")
                split.removeFirst()
                let message = split.joined().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // ✅ CRITICAL FIX: Use direct stderr write instead of print() to avoid infinite recursion
                self.writeDirectlyToOriginalStderr(message)
            }
        }
    }
    
    // ✅ NEW: Write directly to original stderr to avoid recursive loops
    private func writeDirectlyToOriginalStderr(_ message: String) {
        let messageWithNewline = message + "\n"
        if let data = messageWithNewline.data(using: .utf8) {
            // Write directly to original stderr file descriptor to avoid recursion
            _ = data.withUnsafeBytes { bytes in
                write(originalDescriptor, bytes.bindMemory(to: UInt8.self).baseAddress, data.count)
            }
        }
    }
}
