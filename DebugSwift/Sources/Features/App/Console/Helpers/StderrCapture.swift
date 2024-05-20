/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2020-Present Datadog, Inc.
 */

import Foundation

enum StderrCapture {
    static var isCapturing = false
    private static let inputPipe = Pipe()
    private static let outputPipe = Pipe()
    private static var originalDescriptor = FileHandle.standardError.fileDescriptor

    static func startCapturing() {
        guard !isCapturing else { return }

        inputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                StderrCapture.stderrMessage(string: string)
            }

            // Write input back to stderr
            outputPipe.fileHandleForWriting.write(data)
        }
        setvbuf(stderr, nil, _IONBF, 0)

        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        dup2(FileHandle.standardError.fileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor)

        // Intercept STDERR with inputPipe
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor)

        isCapturing = true
    }

    static func syncData() {
        guard isCapturing, inputPipe.fileHandleForReading.isReadable else {
            return
        }

        var synchronizeData: DispatchWorkItem!
        synchronizeData = DispatchWorkItem(block: {
            let auxData = inputPipe.fileHandleForReading.availableData
            if !auxData.isEmpty,
               let string = String(data: auxData, encoding: String.Encoding.utf8) {
                StderrCapture.stderrMessage(string: string)
            }
        })
        DispatchQueue.global().async {
            synchronizeData.perform()
        }
        _ = synchronizeData.wait(timeout: .now() + .milliseconds(10))
    }

    static func stopCapturing() {
        guard isCapturing else { return }

        isCapturing = false
        freopen("/dev/stderr", "a", stderr)
    }

    static func stderrMessage(string: String) {
        if
            string.contains("OSLOG"),
            let message = string.split(separator: "\t").last {
            let message = String(message).trimmingCharacters(in: .whitespacesAndNewlines)
            ConsoleOutput.printAndNSLogOutput.append("\(message)")
        } else {
            ConsoleOutput.errorOutput.append(string)

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
