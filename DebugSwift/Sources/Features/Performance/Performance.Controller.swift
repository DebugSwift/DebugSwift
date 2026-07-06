//
//  Performance.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit

final class PerformanceViewController: BaseTableController, PerformanceToolkitDelegate, MainFeatureType {
    var controllerType: DebugSwiftFeature { .performance }

    lazy var performanceToolkit = PerformanceToolkit(widgetDelegate: self)
    private let memoryWarningSimulator = PerformanceMemoryWarning()
    private let ioMonitor = DiskIOMonitor.shared
    private let diskAnalyzer = DiskAnalyzer()
    private let batteryMonitor = BatteryMonitor.shared

    private var isDiskMonitoringEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "debugswift.disk.monitoringEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "debugswift.disk.monitoringEnabled")
            if newValue { ioMonitor.start() } else { ioMonitor.stop() }
            tableView.reloadData()
        }
    }

    private var isBatteryMonitoringEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "debugswift.battery.monitoringEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "debugswift.battery.monitoringEnabled")
            if newValue { batteryMonitor.start() } else { batteryMonitor.stop() }
            tableView.reloadData()
        }
    }

    enum Identifier: String {
        case value = "ValueTableViewCell"
        case leak = "LeakTableViewCell"
        case memoryWarning = "MemoryWarningTableViewCell"

        init?(rawValue: String?) {
            guard let rawValue else { return nil }
            self.init(rawValue: rawValue)
        }
    }

    private enum Section: Int, CaseIterable {
        case widget
        case cpu
        case memory
        case fps
        case leaks
        case diskToggle
        case diskMetrics
        case diskUsage
        case openFiles
        case batteryToggle
        case batteryStatus
        case batteryHistory
    }

    // MARK: - UIViewController Lifecycle

    override init() {
        super.init()
        performanceToolkit.delegate = self
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        diskAnalyzer.measure()
        if isDiskMonitoringEnabled { ioMonitor.start() }
        if isBatteryMonitoringEnabled { batteryMonitor.start() }
    }

    // MARK: - Setup Methods

    private func setup() {
        title = "Performance"
        tabBarItem = UITabBarItem(
            title: title,
            image: .named("speedometer"),
            tag: 1
        )
    }

    private func setupTableView() {
        tableView.register(
            MenuSwitchTableViewCell.self,
            forCellReuseIdentifier: MenuSwitchTableViewCell.identifier
        )
        tableView.register(
            SparklineMetricCell.self,
            forCellReuseIdentifier: SparklineMetricCell.identifier
        )
        tableView.backgroundColor = UIColor.black
        tableView.showsVerticalScrollIndicator = false
        view.backgroundColor = UIColor.black
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .widget:
            return 1
        case .cpu:
            return 1
        case .memory:
            return 2
        case .fps:
            return 1
        case .leaks:
            if DebugSwift.App.shared.disableMethods.contains(.leaksDetector) { return 0 }
            return 2
        case .diskToggle:
            return 1
        case .diskMetrics:
            return isDiskMonitoringEnabled ? 1 : 0
        case .diskUsage:
            return diskAnalyzer.usageInfo != nil ? 7 : 0
        case .openFiles:
            return isDiskMonitoringEnabled ? ioMonitor.openFiles.count : 0
        case .batteryToggle:
            return 1
        case .batteryStatus:
            return isBatteryMonitoringEnabled && batteryMonitor.isAvailable ? 3 : 0
        case .batteryHistory:
            return isBatteryMonitoringEnabled ? 1 : 0
        }
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .widget: return nil
        case .cpu: return nil
        case .memory: return nil
        case .fps: return nil
        case .leaks:
            if DebugSwift.App.shared.disableMethods.contains(.leaksDetector) { return nil }
            return "Leaks & Threads"
        case .diskToggle: return "Disk I/O"
        case .diskMetrics: return nil
        case .diskUsage: return diskAnalyzer.usageInfo != nil ? "Disk Usage" : nil
        case .openFiles: return isDiskMonitoringEnabled ? "Open Files (\(ioMonitor.openFiles.count))" : nil
        case .batteryToggle: return "Battery"
        case .batteryStatus: return nil
        case .batteryHistory: return isBatteryMonitoringEnabled ? "History" : nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .widget:
            return widgetToggleCell()
        case .cpu:
            return cpuCell(at: indexPath.row)
        case .memory:
            return memoryCell(at: indexPath.row)
        case .fps:
            return fpsCell(at: indexPath.row)
        case .leaks:
            return leaksCell(at: indexPath.row)
        case .diskToggle:
            return diskToggleCell()
        case .diskMetrics:
            return diskMetricsCell(at: indexPath.row)
        case .diskUsage:
            return diskUsageCell(at: indexPath.row)
        case .openFiles:
            return openFileCell(at: indexPath.row)
        case .batteryToggle:
            return batteryToggleCell()
        case .batteryStatus:
            return batteryStatusCell(at: indexPath.row)
        case .batteryHistory:
            return batteryHistoryCell()
        }
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .lightGray
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let type = Identifier(rawValue: cell?.reuseIdentifier)

        switch type {
        case .memoryWarning:
            handleMemoryWarningTap(cell: cell)
        case .leak:
            if indexPath.row == 0 {
                let viewModel = LeaksViewModel()
                let controller = ResourcesGenericController(viewModel: viewModel)
                navigationController?.pushViewController(controller, animated: true)
            } else if indexPath.row == 1 {
                let threadCheckerController = PerformanceThreadCheckerViewController()
                navigationController?.pushViewController(threadCheckerController, animated: true)
            }
        default:
            break
        }
    }

    // MARK: - Cells: Widget

    private func widgetToggleCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuSwitchTableViewCell.identifier
        ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = "Show Floating HUD"
        cell.valueSwitch.isOn = performanceToolkit.isWidgetShown
        cell.valueSwitch.tag = 0
        cell.delegate = self
        return cell
    }

    // MARK: - Cells: CPU

    private func cpuCell(at row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SparklineMetricCell.identifier) as? SparklineMetricCell ?? SparklineMetricCell()
        let peak = performanceToolkit.maxCPU
        let current = performanceToolkit.currentCPU
        cell.configure(
            title: "CPU",
            value: String(format: "%.1f%%", current),
            color: current < 30 ? .systemGreen : current < 70 ? .systemYellow : .systemRed,
            measurements: performanceToolkit.cpuMeasurements,
            peakText: String(format: "Peak %.0f%% · Min %.0f%%", peak, performanceToolkit.cpuMeasurements.min() ?? 0)
        )
        return cell
    }

    // MARK: - Cells: Memory

    private func memoryCell(at row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: SparklineMetricCell.identifier) as? SparklineMetricCell ?? SparklineMetricCell()
            let current = performanceToolkit.currentMemory
            let peak = performanceToolkit.maxMemory
            let valueText: String
            if current >= 1024 {
                valueText = String(format: "%.1f GB", current / 1024)
            } else {
                valueText = String(format: "%.0f MB", current)
            }
            cell.configure(
                title: "Memory",
                value: valueText,
                color: current < 200 ? .systemGreen : current < 500 ? .systemYellow : .systemRed,
                measurements: performanceToolkit.memoryMeasurements,
                peakText: String(format: "Peak %.0fMB · Min %.0fMB", peak, performanceToolkit.memoryMeasurements.min() ?? 0)
            )
            return cell
        case 1:
            return memoryWarningCell()
        default:
            return UITableViewCell()
        }
    }

    private func memoryWarningCell() -> UITableViewCell {
        let cell = reuseCell(for: .memoryWarning)

        if memoryWarningSimulator.isCurrentlySimulating {
            cell.textLabel?.text = "⚠️ Simulating Memory Warning..."
            cell.contentView.backgroundColor = .systemOrange
            cell.selectionStyle = .none
        } else {
            cell.textLabel?.text = "Simulate Memory Warning"
            cell.contentView.backgroundColor = .systemRed
            cell.selectionStyle = .default
        }

        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.textLabel?.textColor = .white
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.layer.masksToBounds = true
        cell.backgroundColor = .clear

        return cell
    }

    // MARK: - Cells: FPS

    private func fpsCell(at row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SparklineMetricCell.identifier) as? SparklineMetricCell ?? SparklineMetricCell()
        let current = performanceToolkit.currentFPS
        let minFPS = performanceToolkit.minFPS
        cell.configure(
            title: "FPS",
            value: String(format: "%.0f fps", current),
            color: current >= 55 ? .systemGreen : current >= 40 ? .systemYellow : .systemRed,
            measurements: performanceToolkit.fpsMeasurements,
            peakText: String(format: "Peak %.0ffps · Min %.0ffps", performanceToolkit.maxFPS, minFPS == 9999 ? 0 : minFPS)
        )
        return cell
    }

    // MARK: - Cells: Leaks

    private func leaksCell(at row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = reuseCell(for: .leak)
            cell.setup(title: "⚠️ Show Leaks", image: .named("chevron.right", default: "Action"))
            return cell
        case 1:
            let cell = reuseCell(for: .leak)
            cell.setup(title: "Thread Checker", image: .named("chevron.right", default: "Action"))
            return cell
        default:
            return UITableViewCell()
        }
    }

    // MARK: - Cells: Disk

    private func diskToggleCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuSwitchTableViewCell.identifier
        ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = "Disk I/O Monitoring"
        cell.valueSwitch.isOn = isDiskMonitoringEnabled
        cell.valueSwitch.tag = 1
        cell.delegate = self
        return cell
    }

    private func diskMetricsCell(at row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SparklineMetricCell.identifier) as? SparklineMetricCell ?? SparklineMetricCell()

        let writeValues = ioMonitor.writeHistory.map { CGFloat($0.bytesPerSecond) }
        let current = ioMonitor.writeBytesPerSecond
        cell.configure(
            title: "Writing",
            value: formattedRate(current),
            color: .systemRed,
            measurements: writeValues,
            peakText: diskPeakMinText(writeValues)
        )
        return cell
    }

    private func diskPeakMinText(_ values: [CGFloat]) -> String {
        guard !values.isEmpty, let peak = values.max(), let min = values.min() else {
            return "Waiting for data…"
        }
        return "Peak \(formattedRateCompact(Double(peak))) · Min \(formattedRateCompact(Double(min)))"
    }

    private func formattedRateCompact(_ bytesPerSecond: Double) -> String {
        let kb = bytesPerSecond / 1024
        if kb < 0.1 { return "0KB/s" }
        if kb < 1024 { return String(format: "%.0fKB/s", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1fMB/s", mb) }
        let gb = mb / 1024
        return String(format: "%.2fGB/s", gb)
    }

    private func diskUsageCell(at row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "DiskUsageCell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        cell.selectionStyle = .none

        guard let info = diskAnalyzer.usageInfo else { return cell }

        switch row {
        case 0:
            cell.textLabel?.text = "Total Space"
            cell.detailTextLabel?.text = formatBytes(info.totalSpace)
        case 1:
            cell.textLabel?.text = "Free Space"
            cell.detailTextLabel?.text = formatBytes(info.freeSpace)
        case 2:
            cell.textLabel?.text = "Bundle Size"
            cell.detailTextLabel?.text = formatBytes(info.bundleSize)
        case 3:
            cell.textLabel?.text = "Caches"
            cell.detailTextLabel?.text = formatBytes(info.cachesSize)
        case 4:
            cell.textLabel?.text = "Temp"
            cell.detailTextLabel?.text = formatBytes(info.tempSize)
        case 5:
            cell.textLabel?.text = "Documents"
            cell.detailTextLabel?.text = formatBytes(info.documentsSize)
        case 6:
            cell.textLabel?.text = "24h Writes (MetricKit)"
            cell.detailTextLabel?.text = DiskWriteTracker.shared.metricKitCumulativeWrites ?? "Pending…"
            cell.detailTextLabel?.textColor = .systemTeal
        default:
            break
        }
        return cell
    }

    private func openFileCell(at row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "OpenFileCell")
        cell.backgroundColor = .black
        cell.selectionStyle = .none

        guard row < ioMonitor.openFiles.count else { return cell }
        let file = ioMonitor.openFiles[row]

        cell.textLabel?.text = "fd \(file.descriptor) [\(file.fileType.rawValue)]"
        cell.textLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        cell.textLabel?.textColor = fileTypeColor(file.fileType)

        cell.detailTextLabel?.text = file.path
        cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        cell.detailTextLabel?.textColor = .gray
        cell.detailTextLabel?.lineBreakMode = .byTruncatingMiddle

        return cell
    }

    // MARK: - Cells: Battery

    private func batteryToggleCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuSwitchTableViewCell.identifier
        ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = "Battery Monitoring"
        cell.valueSwitch.isOn = isBatteryMonitoringEnabled
        cell.valueSwitch.tag = 2
        cell.delegate = self
        return cell
    }

    private func batteryStatusCell(at row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "BatteryStatusCell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.selectionStyle = .none

        // Use latest snapshot if available, fall back to live values
        let latestSnapshot = batteryMonitor.snapshots.last

        switch row {
        case 0:
            let level = latestSnapshot?.level ?? batteryMonitor.currentLevel
            cell.textLabel?.text = "Battery Level"
            cell.detailTextLabel?.text = level >= 0 ? "\(Int(level * 100))%" : "N/A"
            cell.detailTextLabel?.textColor = batteryLevelColor(level)
        case 1:
            let state = latestSnapshot?.state ?? batteryMonitor.currentState
            cell.textLabel?.text = "State"
            cell.detailTextLabel?.text = state.displayName
            cell.detailTextLabel?.textColor = .lightGray
        case 2:
            let impact = batteryMonitor.currentImpact
            cell.textLabel?.text = "Energy Impact"
            cell.detailTextLabel?.text = impact?.level.label ?? "Unknown"
            cell.detailTextLabel?.textColor = impact?.level.color ?? .lightGray
        default:
            break
        }

        return cell
    }

    private func batteryHistoryCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SparklineMetricCell.identifier
        ) as? SparklineMetricCell ?? SparklineMetricCell()

        let measurements = batteryMonitor.snapshots.map { CGFloat($0.level * 100) }

        guard measurements.count >= 2 else {
            cell.configure(
                title: "Battery Level",
                value: "—",
                color: .systemGray,
                measurements: [],
                peakText: "Waiting for data…"
            )
            return cell
        }

        let current = measurements.last ?? 0
        let peak = measurements.max() ?? 0
        let min = measurements.min() ?? 0

        cell.configure(
            title: "Battery Level",
            value: "\(Int(current))%",
            color: batteryLevelColor(Float(current / 100)),
            measurements: measurements,
            peakText: "Peak \(Int(peak))% · Min \(Int(min))%"
        )

        return cell
    }

    // MARK: - Helpers

    private func batteryLevelColor(_ level: Float) -> UIColor {
        switch level {
        case 0.5...: return .systemGreen
        case 0.2..<0.5: return .systemYellow
        default: return .systemRed
        }
    }

    private func reuseCell(for reuseIdentifier: Identifier = .value) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier.rawValue) ?? UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier.rawValue)
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.black
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        return cell
    }

    // MARK: - Helpers

    private func formattedRate(_ bytesPerSecond: Double) -> String {
        let kb = bytesPerSecond / 1024
        if kb < 0.1 { return "0 KB/s" }
        if kb < 1024 { return String(format: "%.0f KB/s", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB/s", mb) }
        let gb = mb / 1024
        return String(format: "%.2f GB/s", gb)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func fileTypeColor(_ type: OpenFileDescriptor.FileType) -> UIColor {
        switch type {
        case .readOnly: return .systemGreen
        case .writeOnly: return .systemRed
        case .readWrite: return .systemYellow
        }
    }

    // MARK: - Memory Warning Handling

    private func handleMemoryWarningTap(cell: UITableViewCell?) {
        if memoryWarningSimulator.isCurrentlySimulating {
            showStopSimulationAlert()
            return
        }
        cell?.simulateButtonTap()
        showMemoryWarningConfirmation()
    }

    private func showMemoryWarningConfirmation() {
        let alert = UIAlertController(
            title: "Simulate Memory Warning",
            message: "This will trigger a memory warning throughout your app and simulate memory pressure.\n\n⚠️ May cause temporary app slowdown.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Simulate Now", style: .default) { [weak self] _ in
            self?.executeMemoryWarningSimulation()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showStopSimulationAlert() {
        let alert = UIAlertController(
            title: "Stop Memory Simulation?",
            message: "A memory warning simulation is currently running.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Stop", style: .destructive) { [weak self] _ in
            self?.memoryWarningSimulator.stopSimulation()
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel))
        present(alert, animated: true)
    }

    private func executeMemoryWarningSimulation() {
        tableView.reloadData()
        memoryWarningSimulator.generate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// MARK: - MenuSwitchTableViewCellDelegate

extension PerformanceViewController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(_ cell: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        switch cell.valueSwitch.tag {
        case 0: performanceToolkit.isWidgetShown = isOn
        case 1: isDiskMonitoringEnabled = isOn
        case 2: isBatteryMonitoringEnabled = isOn
        default: break
        }
    }
}

// MARK: - PerformanceToolkitDelegate

extension PerformanceViewController {
    func performanceToolkitDidUpdateStats(_: PerformanceToolkit) {
        tableView.reloadData()
    }
}

extension PerformanceViewController: PerformanceWidgetViewDelegate {
    func performanceWidgetView(
        _: PerformanceWidgetView, didTapOnSection _: PerformanceSection
    ) {}
}
