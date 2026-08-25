//
//  BatteryDebugController.swift
//  DebugSwift
//
//  Created by emircan.saglam on 7.06.2026.
//

import UIKit

final class BatteryDebugController: BaseTableController {

    // MARK: - Properties

    private let monitor = BatteryMonitor.shared
    private var isMonitoringEnabled = false {
        didSet {
            UserDefaults.standard.set(isMonitoringEnabled, forKey: "debugswift.battery.monitoringEnabled")
            isMonitoringEnabled ? monitor.start() : monitor.stop()
            tableView.reloadData()
        }
    }
    private var refreshTimer: Timer?

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case toggle
        case status
        case history
    }

    // MARK: - Init

    override init() {
        super.init()
        title = "Battery"
        isMonitoringEnabled = UserDefaults.standard.bool(forKey: "debugswift.battery.monitoringEnabled")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(MenuSwitchTableViewCell.self, forCellReuseIdentifier: MenuSwitchTableViewCell.identifier)
        tableView.register(SparklineMetricCell.self, forCellReuseIdentifier: SparklineMetricCell.identifier)
        tableView.backgroundColor = .black
        view.backgroundColor = .black

        if isMonitoringEnabled {
            monitor.start()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isMonitoringEnabled else { return }
                self.tableView.reloadData()
            }
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .toggle: return 1
        case .status: return isMonitoringEnabled && monitor.isAvailable ? 3 : 0
        case .history: return isMonitoringEnabled ? 1 : 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .toggle: return nil
        case .status: return isMonitoringEnabled && monitor.isAvailable ? "Status" : nil
        case .history: return isMonitoringEnabled ? "History" : nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .toggle: return toggleCell()
        case .status: return statusCell(at: indexPath.row)
        case .history: return historyCell()
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .lightGray
    }

    // MARK: - Cells

    private func toggleCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MenuSwitchTableViewCell.identifier) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = "Battery Monitoring"
        cell.valueSwitch.isOn = isMonitoringEnabled
        cell.delegate = self
        return cell
    }

    private func statusCell(at row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "BatteryStatusCell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.selectionStyle = .none

        let latestSnapshot = monitor.snapshots.last

        switch row {
        case 0:
            let level = latestSnapshot?.level ?? monitor.currentLevel
            cell.textLabel?.text = "Battery Level"
            cell.detailTextLabel?.text = level >= 0 ? "\(Int(level * 100))%" : "N/A"
            cell.detailTextLabel?.textColor = levelColor(level)
        case 1:
            let state = latestSnapshot?.state ?? monitor.currentState
            cell.textLabel?.text = "State"
            cell.detailTextLabel?.text = state.displayName
            cell.detailTextLabel?.textColor = .lightGray
        case 2:
            let impact = monitor.currentImpact
            cell.textLabel?.text = "Energy Impact"
            cell.detailTextLabel?.text = impact?.level.label ?? "Unknown"
            cell.detailTextLabel?.textColor = impact?.level.color ?? .lightGray
        default:
            break
        }

        return cell
    }

    private func historyCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SparklineMetricCell.identifier) as? SparklineMetricCell ?? .init()

        let measurements = monitor.snapshots.map { CGFloat($0.level * 100) }

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
            color: levelColor(Float(current / 100)),
            measurements: measurements,
            peakText: "Peak \(Int(peak))% · Min \(Int(min))%"
        )

        return cell
    }

    // MARK: - Helpers

    private func levelColor(_ level: Float) -> UIColor {
        switch level {
        case 0.5...: return .systemGreen
        case 0.2..<0.5: return .systemYellow
        default: return .systemRed
        }
    }
}

// MARK: - MenuSwitchTableViewCellDelegate

extension BatteryDebugController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(_ cell: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        isMonitoringEnabled = isOn
    }
}
