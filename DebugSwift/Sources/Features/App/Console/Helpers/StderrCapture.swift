/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2020-Present Datadog, Inc.
 */

@preconcurrency import Foundation

class StderrCapture: @unchecked Sendable {
    
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
    
    private let captureQueue = DispatchQueue(
        label: "com.debugswift.stderr.capture",
        qos: .utility
    )
    
    // Changed to serial queue to prevent concurrent writes to FileHandle and file descriptors
    private let processingQueue = DispatchQueue(
        label: "com.debugswift.stderr.processing",
        qos: .default
    )
    
    // Lock for FileHandle write operations to ensure thread-safety
    private let writeLock = NSLock()
    
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
        // Double-checked locking to prevent concurrent initialization
        guard !isCapturing else { return }
        
        stateLock.lock()
        guard !_isCapturing else {
            stateLock.unlock()
            return
        }
        _isCapturing = true
        stateLock.unlock()

        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let self = self, self.isCapturing else { return }
            
            self.captureQueue.async {
                let data = fileHandle.availableData
                if let string = String(data: data, encoding: .utf8), !string.isEmpty {
                    self.processingQueue.async {
                        self.stderrMessageSafe(string: string)
                    }
                }

                // Write back to stderr to maintain output - thread-safe
                self.writeLock.lock()
                defer { self.writeLock.unlock() }
                self.outputPipe.fileHandleForWriting.write(data)
            }
        }
        
        setvbuf(stderr, nil, _IONBF, 0)

        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        if dup2(FileHandle.standardError.fileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to duplicate stderr for output pipe")
            stateLock.lock()
            _isCapturing = false
            stateLock.unlock()
            return
        }

        // Intercept STDERR with inputPipe
        if dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to redirect stderr to input pipe")
            stateLock.lock()
            _isCapturing = false
            stateLock.unlock()
            return
        }
    }

    func syncData() {
        guard isCapturing, inputPipe.fileHandleForReading.isReadable else {
            return
        }

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
        // Double-checked locking
        guard isCapturing else { return }
        
        stateLock.lock()
        guard _isCapturing else {
            stateLock.unlock()
            return
        }
        _isCapturing = false
        stateLock.unlock()
        
        inputPipe.fileHandleForReading.readabilityHandler = nil
        freopen("/dev/stderr", "a", stderr)
    }

    private func stderrMessageSafe(string: String) {
        if string.contains("OSLOG"),
           let message = string.split(separator: "\t").last {
            let message = String(message).trimmingCharacters(in: .whitespacesAndNewlines)
            ConsoleOutput.shared.addPrintAndNSLogOutput("\(message)")
        } else {
            ConsoleOutput.shared.addErrorOutput(string)

            if string.contains("]") {
                var split = string.split(separator: "]")
                split.removeFirst()
                let message = split.joined().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Use direct stderr write instead of print() to avoid infinite recursion
                self.writeDirectlyToOriginalStderr(message)
            }
        }
    }
    
    private func writeDirectlyToOriginalStderr(_ message: String) {
        writeLock.lock()
        defer { writeLock.unlock() }
        
        let messageWithNewline = message + "\n"
        if let data = messageWithNewline.data(using: .utf8) {
            // Write directly to original stderr file descriptor to avoid recursion
            _ = data.withUnsafeBytes { bytes in
                write(originalDescriptor, bytes.bindMemory(to: UInt8.self).baseAddress, data.count)
            }
        }
    }
}
