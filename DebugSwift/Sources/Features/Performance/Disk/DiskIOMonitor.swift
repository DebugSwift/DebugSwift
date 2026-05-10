//
//  DiskIOMonitor.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation

@MainActor
final class DiskIOMonitor: ObservableObject {
    static let shared = DiskIOMonitor()

    @Published private(set) var writeBytesPerSecond: Double = 0
    @Published private(set) var writeHistory: [DiskIOSample] = []
    @Published private(set) var openFiles: [OpenFileDescriptor] = []

    private let historyLimit = 60
    private var timer: Timer?
    private var isRunning = false

    private var previousWriteBytes: UInt64 = 0

    private init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true

        previousWriteBytes = DiskWriteTracker.shared.totalBytesWritten

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        let currentWrite = DiskWriteTracker.shared.totalBytesWritten

        let deltaWrite = currentWrite >= previousWriteBytes
            ? currentWrite - previousWriteBytes : 0

        previousWriteBytes = currentWrite

        writeBytesPerSecond = Double(deltaWrite)

        let now = Date()
        writeHistory.append(DiskIOSample(bytesPerSecond: writeBytesPerSecond, timestamp: now))

        if writeHistory.count > historyLimit {
            writeHistory.removeFirst(writeHistory.count - historyLimit)
        }

        openFiles = Self.listOpenFiles()
    }

    // MARK: - Open File Descriptors (POSIX - fully public)

    private nonisolated static func listOpenFiles() -> [OpenFileDescriptor] {
        var descriptors: [OpenFileDescriptor] = []
        let maxFD: Int32 = 256

        for fd: Int32 in 0..<maxFD {
            var buf = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            let ret = fcntl(fd, F_GETPATH, &buf)
            guard ret != -1 else { continue }

            let path = String(cString: buf)
            let flags = fcntl(fd, F_GETFL)
            guard flags != -1 else { continue }

            let accessMode = flags & O_ACCMODE
            let fileType: OpenFileDescriptor.FileType
            switch accessMode {
            case O_WRONLY:
                fileType = .writeOnly
            case O_RDWR:
                fileType = .readWrite
            default:
                fileType = .readOnly
            }

            descriptors.append(OpenFileDescriptor(descriptor: fd, path: path, fileType: fileType))
        }

        return descriptors
    }
}
