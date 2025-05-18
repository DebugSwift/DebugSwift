/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2020-Present Datadog, Inc.
 */

@preconcurrency import Foundation

class StderrCapture: @unchecked Sendable {
    var isCapturing = false
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private var originalDescriptor = FileHandle.standardError.fileDescriptor
    
    private init() {}
    static let shared = StderrCapture()

    func startCapturing() {
        guard !isCapturing else { return }

        inputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                self.stderrMessage(string: string)
            }

            // Write input back to stderr
            self.outputPipe.fileHandleForWriting.write(data)
        }
        setvbuf(stderr, nil, _IONBF, 0)

        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        dup2(FileHandle.standardError.fileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor)

        // Intercept STDERR with inputPipe
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor)

        isCapturing = true
    }

    func syncData() {
        guard isCapturing, inputPipe.fileHandleForReading.isReadable else {
            return
        }

        let synchronizeData = DispatchWorkItem {
            let auxData = self.inputPipe.fileHandleForReading.availableData
            if !auxData.isEmpty,
               let string = String(data: auxData, encoding: .utf8) {
                self.stderrMessage(string: string)
            }
        }

        DispatchQueue.global().async {
            synchronizeData.perform()
        }

        _ = synchronizeData.wait(timeout: .now() + .milliseconds(10))
    }

    func stopCapturing() {
        guard isCapturing else { return }

        isCapturing = false
        freopen("/dev/stderr", "a", stderr)
    }

    func stderrMessage(string: String) {
        if
            string.contains("OSLOG"),
            let message = string.split(separator: "\t").last {
            let message = String(message).trimmingCharacters(in: .whitespacesAndNewlines)
            ConsoleOutput.shared.printAndNSLogOutput.append("\(message)")
        } else {
            ConsoleOutput.shared.errorOutput.append(string)

            if
                string.contains("]") {
                var split = string.split(separator: "]")
                split.removeFirst()
                let message = split.joined().trimmingCharacters(in: .whitespacesAndNewlines)
                print(message) // Logs into print
            }
        }
    }
}
