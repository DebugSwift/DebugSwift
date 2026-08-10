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
        stateLock.unlock()

        // Save an owned copy of the real stderr fd *before* redirecting fd 2
        // onto the capture pipe. Without this, originalDescriptor would alias
        // the capture pipe and writeDirectlyToOriginalStderr would feed back
        // into the capture loop (infinite recursion).
        originalDescriptor = dup(FileHandle.standardError.fileDescriptor)
        if originalDescriptor == -1 {
            print("[DebugSwift] Failed to duplicate original stderr descriptor")
            return
        }

        setvbuf(stderr, nil, _IONBF, 0)
        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        if dup2(FileHandle.standardError.fileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to duplicate stderr for output pipe")
            close(originalDescriptor)
            originalDescriptor = -1
            return
        }

        // Intercept STDERR with inputPipe
        if dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor) == -1 {
            print("[DebugSwift] Failed to redirect stderr to input pipe")
            close(originalDescriptor)
            originalDescriptor = -1
            return
        }
        // fd 2 is now redirected and the handler is about to be armed —
        // publish the capturing flag so isCapturing faithfully means
        // "fd 2 is redirected and the handler is armed." Setting it earlier
        // created a window where isCapturing returned true before fd 2 was
        // actually redirected, causing tests to write markers to real stderr
        // (which escaped capture) under CI startup load (#433).
        stateLock.lock()
        _isCapturing = true
        stateLock.unlock()
        // Consume availableData synchronously inside the readabilityHandler.
        // The read source re-fires as long as data is unconsumed, so reading
        // it in a deferred captureQueue.async block left the source signalled
        // and caused it to re-fire immediately, enqueuing a new dispatch block
        // per callback and leaking unbounded _Block_copy allocations (#433).
        // Only the heavier parsing/forwarding work is dispatched off-handler.
        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let self = self, self.isCapturing else { return }
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }
            self.writeLock.lock()
            self.outputPipe.fileHandleForWriting.write(data)
            self.writeLock.unlock()
            self.processingQueue.async {
                guard let string = String(data: data, encoding: .utf8),
                      !string.isEmpty else { return }
                self.stderrMessageSafe(string: string)
            }
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
        // Restore fd 2 to the real stderr. The dup2 call makes fd 2 point
        // at the original stderr destination again. We do NOT use
        // freopen("/dev/stderr", "a", stderr) here because it closes fd 2
        // first and then tries to open /dev/fd/2 — which is now closed,
        // so it fails with EBADF and leaves fd 2 permanently invalid.
        // That made the next startCapturing()'s dup(2) fail (returning -1),
        // and silently broke all post-stop stderr output (NSLog, crash logs,
        // OS-level writes).
        // After dup2 restores the fd, the C stderr FILE* stream still
        // references fd 2, so it writes to the right destination. We just
        // clear any error state and reset the buffer mode.
        if originalDescriptor != -1 {
            dup2(originalDescriptor, FileHandle.standardError.fileDescriptor)
            close(originalDescriptor)
            originalDescriptor = -1
        }
        clearerr(stderr)
        setvbuf(stderr, nil, _IOLBF, 0)
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
