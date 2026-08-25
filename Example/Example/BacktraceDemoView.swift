//
//  BacktraceDemoView.swift
//  Example
//
//  Demonstrates DebugSwift.Performance.Backtrace.capture() —
//  programmatic backtrace capture during normal execution.
//

import SwiftUI
import DebugSwift

struct BacktraceDemoView: View {
    @State private var captures: [CapturedBacktrace] = []
    @State private var label = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Backtrace Capture Demo")
                    .font(.title2.bold())

                Text("Demonstrates `DebugSwift.Performance.Backtrace.capture()` — "
                    + "captures the current call stack programmatically (not a crash). "
                    + "View captures in DebugSwift → Performance → Backtrace → View Captures.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Label (optional)")
                        .font(.subheadline)
                    TextField("e.g. checkout-button-tap", text: $label)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: captureNow) {
                    Label("Capture Backtrace", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(8)
                }

                Button(action: captureFromNestedCall) {
                    Label("Capture from nested call", systemImage: "arrow.triangle.branch")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(8)
                }

                Button(action: clearAll) {
                    Label("Clear all captures", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(8)
                }

                Divider()

                Text("Captures in this session: \(captures.count)")
                    .font(.subheadline.bold())

                if captures.isEmpty {
                    Text("No captures yet. Tap a button above.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(captures, id: \.id) { bt in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(labelText(bt))
                                .font(.caption.bold())

                            if let firstFrame = bt.frames.first {
                                Text("Frame 0: \(firstFrame.symbol)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Text("\(bt.frames.count) frame\(bt.frames.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Backtrace Demo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refresh() }
    }

    private func captureNow() {
        _ = DebugSwift.Performance.Backtrace.capture(label: label.isEmpty ? nil : label)
        refresh()
    }

    private func captureFromNestedCall() {
        deeplyNestedCapture(depth: 3, label: label.isEmpty ? "nested-3" : label)
        refresh()
    }

    private func deeplyNestedCapture(depth: Int, label: String) {
        if depth > 0 {
            deeplyNestedCapture(depth: depth - 1, label: label)
        } else {
            _ = DebugSwift.Performance.Backtrace.capture(label: label)
        }
    }

    private func clearAll() {
        DebugSwift.Performance.Backtrace.clear()
        refresh()
    }

    private func refresh() {
        captures = DebugSwift.Performance.Backtrace.captured
    }

    // MARK: - Formatting

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()

    private func labelText(_ bt: CapturedBacktrace) -> String {
        let prefix = bt.label.map { "\($0) · " } ?? ""
        return "\(prefix)\(Self.dateFormatter.string(from: bt.timestamp))"
    }
}

