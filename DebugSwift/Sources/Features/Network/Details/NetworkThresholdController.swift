//
//  NetworkThresholdController.swift
//  DebugSwift
//
//  Created by DebugSwift on 04/06/25.
//

import UIKit

final class NetworkThresholdController: BaseTableController {
    
    // MARK: - Cell Identifiers
    
    private enum CellIdentifier: String {
        case toggle = "ToggleCell"
        case info = "InfoCell"
        case stepper = "StepperCell"
        case action = "ActionCell"
        case header = "HeaderCell"
    }
    
    // MARK: - Sections
    
    private enum Section: Int, CaseIterable {
        case status
        case configuration
        case endpointLimits
        case recentBreaches
        case actions
        
        var title: String {
            switch self {
            case .status: return "CURRENT STATUS"
            case .configuration: return "CONFIGURATION"
            case .endpointLimits: return "ENDPOINT LIMITS"
            case .recentBreaches: return "RECENT BREACHES"
            case .actions: return "ACTIONS"
            }
        }
    }
    
    // MARK: - Properties
    
    private let tracker = NetworkThresholdTracker.shared
    private var config = NetworkThresholdTracker.shared.getConfig()
    private var endpointThresholds = NetworkThresholdTracker.shared.getEndpointThresholds()
    private var breachHistory = NetworkThresholdTracker.shared.getBreachHistory()
    private var timer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Request Threshold"
        view.backgroundColor = .black
        
        // Register cells with proper styles
        tableView.register(ToggleTableViewCell.self, forCellReuseIdentifier: CellIdentifier.toggle.rawValue)
        tableView.register(StepperTableViewCell.self, forCellReuseIdentifier: CellIdentifier.stepper.rawValue)
        
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        config = tracker.getConfig()
        endpointThresholds = tracker.getEndpointThresholds()
        breachHistory = tracker.getBreachHistory()
        tableView.reloadData()
    }
    
    @objc private func refreshData() {
        loadData()
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateCurrentRequestCount()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCurrentRequestCount() {
        if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: Section.status.rawValue)) {
            DispatchQueue.main.async {
                self.configureInfoCell(cell, at: IndexPath(row: 1, section: Section.status.rawValue))
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleTracking(_ isEnabled: Bool) {
        tracker.setTrackingEnabled(isEnabled)
        config.isEnabled = isEnabled
        tableView.reloadData()
    }
    
    private func toggleRequestBlocking(_ isEnabled: Bool) {
        tracker.setRequestBlocking(isEnabled)
        config.shouldBlockRequests = isEnabled
    }
    
    private func updateThresholdLimit(_ value: Int) {
        tracker.setThreshold(value, timeWindow: config.timeWindow)
        config.limit = value
    }
    
    private func updateTimeWindow(_ value: TimeInterval) {
        tracker.setThreshold(config.limit, timeWindow: value)
        config.timeWindow = value
    }
    
    private func clearHistory() {
        let alert = UIAlertController(
            title: "Clear History",
            message: "Are you sure you want to clear all request history and breach records?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.tracker.clearHistory()
            self?.loadData()
        })
        
        present(alert, animated: true)
    }
    
    private func exportLogs() {
        let logs = tracker.getDetailedLogs()
        let activityVC = UIActivityViewController(
            activityItems: [logs],
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension NetworkThresholdController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .status:
            return 3 // Enable toggle, Current requests, Total breaches
        case .configuration:
            return 3 // Threshold limit, Time window, Block requests toggle
        case .endpointLimits:
            return max(1, endpointThresholds.count)
        case .recentBreaches:
            return max(1, min(5, breachHistory.count))
        case .actions:
            return 2 // Clear history, Export logs
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .status:
            return statusCell(at: indexPath)
        case .configuration:
            return configurationCell(at: indexPath)
        case .endpointLimits:
            return endpointLimitCell(at: indexPath)
        case .recentBreaches:
            return breachCell(at: indexPath)
        case .actions:
            return actionCell(at: indexPath)
        }
    }
    
    // MARK: - Cell Configuration
    
    private func statusCell(at indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0: // Enable tracking toggle
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CellIdentifier.toggle.rawValue,
                for: indexPath
            ) as! ToggleTableViewCell
            
            cell.configure(
                title: "Enable Tracking",
                isOn: config.isEnabled,
                onToggle: { [weak self] isOn in
                    self?.toggleTracking(isOn)
                }
            )
            return cell
            
        case 1: // Current requests
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            configureInfoCell(cell, at: indexPath)
            return cell
            
        case 2: // Total breaches
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Total Breaches"
            cell.detailTextLabel?.text = "\(breachHistory.count)"
            cell.backgroundColor = .black
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .gray
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    private func configureInfoCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        cell.textLabel?.text = "Current Requests"
        
        if config.isEnabled {
            let count = tracker.getCurrentRequestCount()
            let percentage = Int((Double(count) / Double(config.limit)) * 100)
            cell.detailTextLabel?.text = "\(count) / \(config.limit) (\(percentage)%)"
            
            // Color code based on percentage
            if percentage >= 90 {
                cell.detailTextLabel?.textColor = .red
            } else if percentage >= 70 {
                cell.detailTextLabel?.textColor = .orange
            } else {
                cell.detailTextLabel?.textColor = .green
            }
        } else {
            cell.detailTextLabel?.text = "Disabled per \(Int(config.timeWindow))s"
            cell.detailTextLabel?.textColor = .gray
        }
        
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
    }
    
    private func configurationCell(at indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0: // Threshold limit
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CellIdentifier.stepper.rawValue,
                for: indexPath
            ) as! StepperTableViewCell
            
            cell.configure(
                title: "Threshold Limit",
                value: config.limit,
                suffix: "requests",
                min: 1,
                max: 1000,
                step: 10,
                onValueChanged: { [weak self] value in
                    self?.updateThresholdLimit(Int(value))
                }
            )
            return cell
            
        case 1: // Time window
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CellIdentifier.stepper.rawValue,
                for: indexPath
            ) as! StepperTableViewCell
            
            cell.configure(
                title: "Time Window",
                value: Int(config.timeWindow),
                suffix: "seconds",
                min: 10,
                max: 300,
                step: 10,
                onValueChanged: { [weak self] value in
                    self?.updateTimeWindow(TimeInterval(value))
                }
            )
            return cell
            
        case 2: // Block exceeding requests
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CellIdentifier.toggle.rawValue,
                for: indexPath
            ) as! ToggleTableViewCell
            
            cell.configure(
                title: "Block Exceeding Requests",
                isOn: config.shouldBlockRequests,
                onToggle: { [weak self] isOn in
                    self?.toggleRequestBlocking(isOn)
                }
            )
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    private func endpointLimitCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CellIdentifier.info.rawValue,
            for: indexPath
        )
        
        if endpointThresholds.isEmpty {
            cell.textLabel?.text = "No endpoint limits configured"
            cell.textLabel?.textColor = .gray
            cell.textLabel?.textAlignment = .center
            cell.detailTextLabel?.text = nil
        } else {
            let endpoints = Array(endpointThresholds.keys).sorted()
            let endpoint = endpoints[indexPath.row]
            let config = endpointThresholds[endpoint]!
            
            cell.textLabel?.text = endpoint
            cell.detailTextLabel?.text = "\(config.limit) per \(Int(config.timeWindow))s"
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .gray
            cell.accessoryType = .disclosureIndicator
        }
        
        cell.backgroundColor = .black
        return cell
    }
    
    private func breachCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        if breachHistory.isEmpty {
            cell.textLabel?.text = "No threshold breaches"
            cell.textLabel?.textColor = .gray
            cell.textLabel?.textAlignment = .center
            cell.detailTextLabel?.text = nil
        } else {
            let sortedBreaches = breachHistory.sorted { $0.timestamp > $1.timestamp }
            let breach = sortedBreaches[indexPath.row]
            
            cell.textLabel?.text = breach.message
            if #available(iOS 15.0, *) {
                cell.detailTextLabel?.text = breach.timestamp.formatted(date: .abbreviated, time: .shortened)
            } else {

            }
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .gray
        }
        
        cell.backgroundColor = .black
        return cell
    }
    
    private func actionCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Clear History"
            cell.textLabel?.textColor = .red
        case 1:
            cell.textLabel?.text = "Export Logs"
            cell.textLabel?.textColor = .systemBlue
        default:
            break
        }
        
        cell.textLabel?.textAlignment = .center
        cell.backgroundColor = .black
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NetworkThresholdController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .actions:
            if indexPath.row == 0 {
                clearHistory()
            } else if indexPath.row == 1 {
                exportLogs()
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .gray
            header.textLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        }
    }
}
