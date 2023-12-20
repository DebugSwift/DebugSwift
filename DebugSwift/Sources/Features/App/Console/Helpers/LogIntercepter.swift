//
//  Log.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import UIKit

class LogIntercepter {

    public static let shared = LogIntercepter()

    // MARK: - Properties

    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private let queue = DispatchQueue(
        label: "com.debugswift.log.interceptor.queue",
        qos: .default,
        attributes: .concurrent
    )

    var consoleOutput = [String]()

    weak var delegate: LogInterceptorDelegate?

    var logUrl: URL? {
        if let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            let documentsDirectory = URL(fileURLWithPath: path)
            return documentsDirectory.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "app")-output.log")
        }
        return nil
    }

    // MARK: - Lifecycle Methods

    func start() {
        if let logUrl = logUrl {
            do {
                let header =
                    """
                    Start logger
                    DeviceID: \(UIDevice.current.identifierForVendor?.uuidString ?? "none")
                    """
                try header.write(to: logUrl, atomically: true, encoding: .utf8)
            } catch {}
        }

        openConsolePipe()
    }

    func reset() {
        consoleOutput.removeAll()
    }

    private func openConsolePipe() {
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)

        // open a new Pipe to consume the messages on STDOUT and STDERR
        inputPipe = Pipe()
        outputPipe = Pipe()

        guard let inputPipe = inputPipe, let outputPipe = outputPipe else {
            return
        }

        let pipeReadHandle = inputPipe.fileHandleForReading

        /// from documentation
        /// dup2() makes newfd (new file descriptor) be the copy of oldfd
        /// (old file descriptor), closing newfd first if necessary.

        /// here we are copying the STDOUT file descriptor into our output
        /// pipe's file descriptor this is so we can write the strings back
        /// to STDOUT, so it can show up on the xcode console
        dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)

        /// In this case, the newFileDescriptor is the pipe's file descriptor
        /// and the old file descriptor is STDOUT_FILENO and STDERR_FILENO

        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // listen in to the readHandle notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePipeNotification),
            name: FileHandle.readCompletionNotification,
            object: pipeReadHandle
        )

        // state that you want to be notified of any data coming across the pipe
        pipeReadHandle.readInBackgroundAndNotify()

    }

    @objc
    func handlePipeNotification(notification: Notification) {
        inputPipe?.fileHandleForReading.readInBackgroundAndNotify()

        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
           let str = String(data: data, encoding: String.Encoding.utf8),
           let logUrl = logUrl {
            /// write the data back into the output pipe. the output pipe's write
            /// file descriptor points to STDOUT. this allows the logs to show up
            /// on the xcode console
            outputPipe?.fileHandleForWriting.write(data)

            queue.async(flags: .barrier) {
                do {
                    try str.appendLineToURL(logUrl)
                } catch {}
            }

            appendConsoleOutput(str)
        }
    }

    private func appendConsoleOutput(_ consoleOutput: String?) {
        guard let output = consoleOutput else { return }

        if !shouldIgnoreLog(output) && shouldIncludeLog(output) {
            queue.async { [weak self] in
                self?.consoleOutput.append(output)
                self?.delegate?.logUpdated()
            }
        }
    }

    private func shouldIgnoreLog(_ log: String) -> Bool {
        return DebugSwift.Console.ignoredLogs.contains { log.contains($0) }
    }

    private func shouldIncludeLog(_ log: String) -> Bool {
        if DebugSwift.Console.onlyLogs.isEmpty {
            return true
        } else {
            return DebugSwift.Console.onlyLogs.contains { log.contains($0) }
        }
    }
}

extension String {
    func appendLineToURL(_ fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL)
    }

    func appendToURL(_ fileURL: URL) throws {
        if let data = data(using: .utf8) {
            try data.appendToURL(fileURL)
        }
    }
}

extension Data {
    func appendToURL(_ fileURL: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

protocol LogInterceptorDelegate: AnyObject {
    func logUpdated()
}
