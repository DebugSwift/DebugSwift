//
//  DiskDebugController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import UIKit

final class DiskDebugController: BaseTableController {

    private let ioMonitor = DiskIOMonitor.shared
    private let analyzer = DiskAnalyzer()
    private var isMonitoringEnabled = false {
        didSet {
            UserDefaults.standard.set(isMonitoringEnabled, forKey: "debugswift.disk.monitoringEnabled")
            if isMonitoringEnabled {
                ioMonitor.start()
            } else {
                ioMonitor.stop()
            }
            tableView.reloadData()
        }
    }

    private var refreshTimer: Timer?

    override init() {
        super.init()
        title = "Disk I/O"
        isMonitoringEnabled = UserDefaults.standard.bool(forKey: "debugswift.disk.monitoringEnabled")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(
            MenuSwitchTableViewCell.self,
            forCellReuseIdentifier: MenuSwitchTableViewCell.identifier
        )
        tableView.backgroundColor = .black
        view.backgroundColor = .black

        analyzer.measure()

        if isMonitoringEnabled {
            ioMonitor.start()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case toggle
        case metrics
        case diskUsage
        case openFiles
    }

    override func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .toggle:
            return 1
        case .metrics:
            return isMonitoringEnabled ? 1 : 0
        case .diskUsage:
            return analyzer.usageInfo != nil ? 6 : 0
        case .openFiles:
            return isMonitoringEnabled ? ioMonitor.openFiles.count : 0
        }
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .toggle: return nil
        case .metrics: return isMonitoringEnabled ? "I/O Rates" : nil
        case .diskUsage: return analyzer.usageInfo != nil ? "Disk Usage" : nil
        case .openFiles: return isMonitoringEnabled ? "Open Files (\(ioMonitor.openFiles.count))" : nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .toggle:
            return toggleCell()
        case .metrics:
            return metricsCell(at: indexPath.row)
        case .diskUsage:
            return diskUsageCell(at: indexPath.row)
        case .openFiles:
            return openFileCell(at: indexPath.row)
        }
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .lightGray
        }
    }

    // MARK: - Cells

    private func toggleCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuSwitchTableViewCell.identifier
        ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = "Disk I/O Monitoring"
        cell.valueSwitch.isOn = isMonitoringEnabled
        cell.delegate = self
        return cell
    }

    private func metricsCell(at row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "MetricCell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .systemRed
        cell.selectionStyle = .none
        cell.textLabel?.text = "Writing"
        cell.detailTextLabel?.text = formattedRate(ioMonitor.writeBytesPerSecond)
        return cell
    }

    private func diskUsageCell(at row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "DiskUsageCell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        cell.selectionStyle = .none

        guard let info = analyzer.usageInfo else { return cell }

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
}

// MARK: - MenuSwitchTableViewCellDelegate

extension DiskDebugController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(_: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        isMonitoringEnabled = isOn
    }
}
