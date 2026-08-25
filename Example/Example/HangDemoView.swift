//
//  HangDemoView.swift
//  Example
//
//  Created by Matheus Gois (Hang Demo) on 17/07/26.
//

import SwiftUI

/// Blocks the main thread for a configurable duration to trigger the
/// Hang/ANR detector. Requires Hang Detection to be enabled for > 10s
/// (the grace period) in DebugSwift → Performance so the watchdog is active.
struct HangDemoView: View {
    @State private var duration: Double = 1.0
    @State private var isBlocking = false
    @State private var lastResult: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hang / ANR Demo")
                    .font(.title2.bold())

                Text("Blocks the main thread for the chosen duration so the "
                    + "Hang Detector fires. Enable Hang Detection in DebugSwift "
                    + "→ Performance, wait ~10s (grace period), then tap Block.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Block duration: \(String(format: "%.2f", duration))s")
                        .font(.subheadline)

                    Slider(value: $duration, in: 0.25...5.0, step: 0.25)
                        .accentColor(.red)
                }

                Button(action: blockMainThread) {
                    Label("Block main thread", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(8)
                }
                .disabled(isBlocking)

                if isBlocking {
                    ProgressView("Blocking… the UI will freeze.")
                }

                if let lastResult {
                    Text(lastResult)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("After blocking, open DebugSwift → Performance → Hang "
                    + "Detection → View Hangs to see the recorded event with its "
                    + "backtrace pointing at the blocking call below.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Hang Demo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func blockMainThread() {
        isBlocking = true
        lastResult = nil

        // Force the heavy work onto the next runloop tick so the button can
        // update its label before the main thread freezes.
        DispatchQueue.main.async {
            let start = Date()
            let target = self.duration
            // Busy-wait on the main thread — this is exactly the pattern the
            // Hang Detector is built to catch. The backtrace will point here.
            while Date().timeIntervalSince(start) < target {
                // Burn CPU so the compiler can't elide the loop.
                _ = sqrt(Date().timeIntervalSinceReferenceDate)
            }
            self.isBlocking = false
            self.lastResult = "Blocked the main thread for "
                + "\(String(format: "%.2f", target))s. Check View Hangs."
        }
    }
}
