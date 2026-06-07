//
//  BatteryMonitor.swift
//  DebugSwift
//
//  Created by emircan.saglam on 7.06.2026.
//

@preconcurrency import Foundation
import UIKit

/// Monitors battery level, state, and energy impact over time.
/// Sampling occurs every 30 seconds to minimize monitoring overhead.
/// Battery level and state changes are also captured instantly via system notifications.
/// On Simulator, mock data is used since battery APIs are unavailable.
@MainActor
final class BatteryMonitor {
    static let shared = BatteryMonitor()

    // MARK: - Properties

    private(set) var snapshots: [BatterySnapshot] = []
    private(set) var isRunning = false
    private(set) var currentImpact: EnergyImpact?

    private let historyLimit = 60
    private var timer: Timer?

    private init() {}

    // MARK: - Public API

    func start() {
        guard !isRunning else { return }
        isRunning = true
        UIDevice.current.isBatteryMonitoringEnabled = true
        setupNotifications()
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
        removeNotifications()
    }

    var currentLevel: Float {
        UIDevice.current.batteryLevel
    }

    var currentState: UIDevice.BatteryState {
        UIDevice.current.batteryState
    }

    /// Returns false on physical devices where battery APIs are unavailable.
    /// Always returns true on Simulator using mock data.
    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return UIDevice.current.batteryLevel >= 0
        #endif
    }

    // MARK: - Notifications

    /// Observes battery level and state changes for real-time updates
    /// between the 30-second periodic samples.
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
    }

    private func removeNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
    }

    @objc private nonisolated func batteryLevelChanged() {
        Task { @MainActor in
            self.sample()
        }
    }

    @objc private nonisolated func batteryStateChanged() {
        Task { @MainActor in
            self.sample()
        }
    }

    // MARK: - Sampling

    private func sample() {
        #if targetEnvironment(simulator)
        let previousLevel = snapshots.last?.level ?? 0.9
        let level = max(0.1, min(1.0, previousLevel - Float.random(in: 0.01...0.03)))
        let state: UIDevice.BatteryState = .unplugged
        #else
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        guard level >= 0 else { return }
        #endif

        let snapshot = BatterySnapshot(level: level, state: state, timestamp: Date())
        snapshots.append(snapshot)

        if snapshots.count > historyLimit {
            snapshots.removeFirst(snapshots.count - historyLimit)
        }

        currentImpact = EnergyImpact.calculate(
            cpuUsage: Self.currentCPUUsage(),
            state: state
        )
    }

    // MARK: - CPU Usage

    /// Calculates current CPU usage across all threads.
    /// Reuses the same mach thread inspection approach as PerformanceToolkit.
    nonisolated static func currentCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(
                            threadsList[Int(index)],
                            thread_flavor_t(THREAD_BASIC_INFO),
                            $0,
                            &threadInfoCount
                        )
                    }
                }

                guard infoResult == KERN_SUCCESS else { break }

                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU += Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }

            let size = vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), size)
        }

        return totalUsageOfCPU
    }
}

// MARK: - UIDevice.BatteryState

extension UIDevice.BatteryState {
    var displayName: String {
        switch self {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Discharging"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}
