//
//  DiskIOTestView.swift
//  Example
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation
import SwiftUI

struct DiskIOTestView: View {
    @State private var log: [String] = []
    @State private var continuousTask: Task<Void, Never>?

    private let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("disk_io_test", isDirectory: true)

    var body: some View {
        List {
            Section {
                ActionButton(title: "Write Small File (1 KB)", icon: "square.and.arrow.down", color: .blue) {
                    writeFile(size: 1_024, label: "1 KB")
                }
                ActionButton(title: "Write Medium File (1 MB)", icon: "square.and.arrow.down.fill", color: .purple) {
                    writeFile(size: 1_024 * 1_024, label: "1 MB")
                }
                ActionButton(title: "Write Large File (10 MB)", icon: "arrow.down.doc", color: .purple) {
                    writeFile(size: 10 * 1_024 * 1_024, label: "10 MB")
                }
            } header: {
                Text("Single Write")
            }

            Section {
                ActionButton(title: "Write via FileHandle", icon: "pencil.line", color: .orange) {
                    writeViaFileHandle()
                }
                ActionButton(title: "Write via OutputStream", icon: "arrow.right.circle", color: .blue) {
                    writeViaOutputStream()
                }
            } header: {
                Text("Other Write Methods")
            }

            Section {
                if continuousTask == nil {
                    ActionButton(title: "Start Continuous I/O (every 1s)", icon: "play.fill", color: .green) {
                        startContinuous()
                    }
                } else {
                    ActionButton(title: "Stop Continuous I/O", icon: "stop.fill", color: .red) {
                        stopContinuous()
                    }
                }
            } header: {
                Text("Continuous")
            }

            Section {
                ActionButton(title: "Clean Up Test Files", icon: "trash", color: .red) {
                    cleanup()
                }
            }

            if !log.isEmpty {
                Section {
                    ForEach(log.reversed(), id: \.self) { entry in
                        Text(entry)
                            .font(.system(.caption, design: .monospaced))
                    }
                } header: {
                    Text("Log")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Disk I/O Tests")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopContinuous() }
    }

    // MARK: - Writes

    private func writeFile(size: Int, label: String) {
        ensureDir()
        let data = Data(repeating: 0xAB, count: size) as NSData
        let url = tempDir.appendingPathComponent("test_\(label)_\(Int(Date().timeIntervalSince1970)).bin")
        do {
            try data.write(to: url as URL, options: .atomic)
            appendLog("Wrote \(label) → \(url.lastPathComponent)")
        } catch {
            appendLog("Write failed: \(error.localizedDescription)")
        }
    }

    private func writeViaFileHandle() {
        ensureDir()
        let url = tempDir.appendingPathComponent("fh_\(Int(Date().timeIntervalSince1970)).bin")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        do {
            let handle = try FileHandle(forWritingTo: url)
            let chunk = Data(repeating: 0xCD, count: 64 * 1_024)
            for _ in 0..<8 {
                handle.write(chunk)
            }
            handle.closeFile()
            appendLog("FileHandle wrote 512 KB → \(url.lastPathComponent)")
        } catch {
            appendLog("FileHandle write failed: \(error.localizedDescription)")
        }
    }

    private func writeViaOutputStream() {
        ensureDir()
        let url = tempDir.appendingPathComponent("os_\(Int(Date().timeIntervalSince1970)).bin")
        guard let stream = OutputStream(url: url, append: false) else {
            appendLog("OutputStream: couldn't open")
            return
        }
        stream.open()
        let bytes = [UInt8](repeating: 0xEF, count: 256 * 1_024)
        let written = stream.write(bytes, maxLength: bytes.count)
        stream.close()
        appendLog("OutputStream wrote \(written) bytes → \(url.lastPathComponent)")
    }

    // MARK: - Continuous

    private func startContinuous() {
        continuousTask = Task {
            var iteration = 0
            while !Task.isCancelled {
                iteration += 1
                writeFile(size: 100 * 1_024, label: "continuous_\(iteration)")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        appendLog("Continuous I/O started")
    }

    private func stopContinuous() {
        continuousTask?.cancel()
        continuousTask = nil
        appendLog("Continuous I/O stopped")
    }

    // MARK: - Cleanup

    private func cleanup() {
        try? FileManager.default.removeItem(at: tempDir)
        appendLog("Cleaned up test directory")
    }

    // MARK: - Helpers

    private func ensureDir() {
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        let ts = formatter.string(from: Date())
        log.append("[\(ts)] \(message)")
    }
}

// MARK: - ActionButton

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label(title, systemImage: icon)
                .foregroundColor(color)
        }
    }
}
