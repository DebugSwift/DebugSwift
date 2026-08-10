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
    private var originalDescriptor: Int32 = -1
    
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

        // Save an owned copy of the real stderr fd *before* redirecting fd 2
        // onto the capture pipe. Without this, originalDescriptor would alias
        // the capture pipe and writeDirectlyToOriginalStderr would feed back
        // into the capture loop (infinite recursion).
        originalDescriptor = dup(FileHandle.standardError.fileDescriptor)
        if originalDescriptor == -1 {
            print("[DebugSwift] Failed to duplicate original stderr descriptor")
            stateLock.lock()
            _isCapturing = false
            stateLock.unlock()
            return
        }

        // Consume availableData synchronously inside the readabilityHandler.
        // The read source re-fires as long as data is unconsumed, so reading
        // it in a deferred captureQueue.async block left the source signalled
        // and caused it to re-fire immediately, enqueuing a new dispatch block
        // per callback and leaking unbounded _Block_copy allocations (#433).
        // Only the heavier parsing/forwarding work is dispatched off-handler.
        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let self = self, self.isCapturing else { return }

            // Read synchronously — clears the read source's signal so it does
            // not re-fire until new bytes arrive. Empty data means EOF.
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }

            // Forward to stderr (passthrough) on the I/O queue.
            self.writeLock.lock()
            self.outputPipe.fileHandleForWriting.write(data)
            self.writeLock.unlock()

            // Parse + forward to the console on a background queue; keep the
            // readabilityHandler off the hot path.
            self.processingQueue.async {
                guard let string = String(data: data, encoding: .utf8),
                      !string.isEmpty else { return }
                self.stderrMessageSafe(string: string)
            }
        }

        setvbuf(stderr, nil, _IONBF, 0)

        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        if dup2(FileHandle.standardError.fileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to duplicate stderr for output pipe")
            close(originalDescriptor)
            originalDescriptor = -1
            stateLock.lock()
            _isCapturing = false
            stateLock.unlock()
            return
        }

        // Intercept STDERR with inputPipe
        if dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to redirect stderr to input pipe")
            close(originalDescriptor)
            originalDescriptor = -1
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
        // Restore fd 2 to the real stderr *before* freopen: "/dev/stderr"
        // resolves to /dev/fd/2, which after the capture redirect points at
        // the capture pipe. Without this, freopen reopens stderr onto the
        // capture pipe and stderr stays redirected after stop.
        if originalDescriptor != -1 {
            dup2(originalDescriptor, FileHandle.standardError.fileDescriptor)
            close(originalDescriptor)
            originalDescriptor = -1
        }
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
