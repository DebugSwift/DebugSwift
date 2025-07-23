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

    var selectedSection: PerformanceSection = .cpu
    lazy var performanceToolkit = PerformanceToolkit(widgetDelegate: self)
    private let memoryWarningSimulator = PerformanceMemoryWarning()

    enum Identifier: String {
        case segmentedControl = "SegmentedControlTableViewCell"
        case value = "ValueTableViewCell"
        case chart = "ChartTableViewCell"
        case leak = "LeakTableViewCell"
        case memoryWarning = "MemoryWarningTableViewCell"

        init?(rawValue: String?) {
            guard let rawValue else { return nil }
            self.init(rawValue: rawValue)
        }
    }

    private let markedTimesInterval: TimeInterval = 20.0
    private let chartCellRatioConstant: CGFloat = 20.0

    enum PerformanceTableViewSection: Int {
        case toggle
        case segmentedControl
        case statistics
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
            MenuSegmentedControlTableViewCell.self,
            forCellReuseIdentifier: Identifier.segmentedControl.rawValue
        )
        tableView.register(
            MenuChartTableViewCell.self,
            forCellReuseIdentifier: Identifier.chart.rawValue
        )

        tableView.backgroundColor = UIColor.black
        tableView.showsVerticalScrollIndicator = false
        view.backgroundColor = UIColor.black
    }

    // MARK: - Updating section

    func setSelectedSection(_ selectedSection: PerformanceSection) {
        self.selectedSection = selectedSection
        reloadStatisticsSection(animated: true)
        refreshSegmentedControlCell()
    }

    // MARK: - Reloading table view

    func reloadStatisticsSection(animated: Bool) {
        let animation: UITableView.RowAnimation = animated ? .fade : .none
        let sectionsToReload = IndexSet(integer: PerformanceTableViewSection.statistics.rawValue)
        tableView.reloadSections(sectionsToReload, with: animation)
    }

    func refreshSegmentedControlCell() {
        let segmentedControlIndexPath = IndexPath(
            row: 0, section: PerformanceTableViewSection.segmentedControl.rawValue
        )
        if let segmentedControlCell = tableView.cellForRow(at: segmentedControlIndexPath)
            as? MenuSegmentedControlTableViewCell {
            segmentedControlCell.segmentedControl.selectedSegmentIndex = selectedSection.rawValue
        }
    }

    // MARK: - Statistics section

    func numberOfRowsInStatisticsSection() -> Int {
        switch selectedSection {
        case .cpu, .fps:
            return 3
        case .memory:
            return 4
        case .leaks:
            return 2
        }
    }

    func statisticsCellForRow(at index: Int) -> UITableViewCell? {
        switch selectedSection {
        case .cpu:
            return cpuStatisticsCellForRow(at: index)
        case .memory:
            return memoryStatisticsCellForRow(at: index)
        case .fps:
            return fpsStatisticsCellForRow(at: index)
        case .leaks:
            return leaksStatisticsCellForRow(at: index)
        }
    }

    func cpuStatisticsCellForRow(at index: Int) -> UITableViewCell? {
        switch index {
        case 0:
            let cell = reuseCell()
            cell.textLabel?.text = "CPU usage"
            cell.detailTextLabel?.text = String(format: "%.1lf%%", performanceToolkit.currentCPU)
            return cell
        case 1:
            let cell = reuseCell()
            cell.textLabel?.text = "Max CPU usage"
            cell.detailTextLabel?.text = String(format: "%.1lf%%", performanceToolkit.maxCPU)
            return cell
        case 2:
            guard let chartCell = reuseCell(for: .chart) as? MenuChartTableViewCell
            else { return nil }
            configureChartCell(
                chartCell,
                value: performanceToolkit.maxCPU,
                measurements: performanceToolkit.cpuMeasurements,
                markedValueFormat: "%.1lf%%"
            )
            return chartCell
        default:
            return nil
        }
    }

    func memoryStatisticsCellForRow(at index: Int) -> UITableViewCell? {
        switch index {
        case 0:
            let cell = reuseCell()
            cell.textLabel?.text = "Memory usage"
            cell.detailTextLabel?.text = String(format: "%.1lf MB", performanceToolkit.currentMemory)
            return cell
        case 1:
            let cell = reuseCell()
            cell.textLabel?.text = "Max memory usage"
            cell.detailTextLabel?.text = String(format: "%.1lf MB", performanceToolkit.maxMemory)
            return cell
        case 2:
            let cell = reuseCell(for: .memoryWarning)
            
            // Dynamic text based on simulation state
            if memoryWarningSimulator.isCurrentlySimulating {
                cell.textLabel?.text = "⚠️ Simulating Memory Warning..."
                cell.contentView.backgroundColor = .systemOrange
                cell.selectionStyle = .none
            } else {
                cell.textLabel?.text = "🚨 Simulate Memory Warning"
                cell.contentView.backgroundColor = .systemRed
                cell.selectionStyle = .default
            }
            
            // Add subtle gradient effect
            if cell.contentView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) == nil {
                let gradient = CAGradientLayer()
                gradient.colors = [
                    cell.contentView.backgroundColor?.cgColor ?? UIColor.systemRed.cgColor,
                    cell.contentView.backgroundColor?.withAlphaComponent(0.8).cgColor ?? UIColor.systemRed.withAlphaComponent(0.8).cgColor
                ]
                gradient.startPoint = CGPoint(x: 0, y: 0)
                gradient.endPoint = CGPoint(x: 1, y: 1)
                gradient.cornerRadius = 8
                cell.contentView.layer.insertSublayer(gradient, at: 0)
                
                // Update gradient frame when cell is laid out
                DispatchQueue.main.async {
                    gradient.frame = cell.contentView.bounds
                }
            }
            
            // Style the text
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            cell.textLabel?.textColor = .white
            cell.contentView.layer.cornerRadius = 8
            cell.contentView.layer.masksToBounds = true
            cell.backgroundColor = .clear
            
            return cell

        case 3:
            guard let chartCell = reuseCell(for: .chart) as? MenuChartTableViewCell else { return nil }
            configureChartCell(
                chartCell,
                value: performanceToolkit.maxMemory,
                measurements: performanceToolkit.memoryMeasurements,
                markedValueFormat: "%.1lf MB"
            )
            return chartCell
        default:
            return nil
        }
    }

    func fpsStatisticsCellForRow(at index: Int) -> UITableViewCell? {
        let cell = reuseCell()

        switch index {
        case 0:
            cell.textLabel?.text = "FPS"
            cell.detailTextLabel?.text = String(format: "%.0lf", performanceToolkit.currentFPS)
        case 1:
            cell.textLabel?.text = "Min FPS"
            cell.detailTextLabel?.text = String(format: "%.0lf", performanceToolkit.minFPS)
        case 2:
            guard let chartCell = reuseCell(for: .chart) as? MenuChartTableViewCell else { return nil }
            configureChartCell(
                chartCell,
                value: performanceToolkit.minFPS,
                measurements: performanceToolkit.fpsMeasurements,
                markedValueFormat: "%.0lf"
            )
            return chartCell
        default:
            return nil
        }

        return cell
    }

    func leaksStatisticsCellForRow(at index: Int) -> UITableViewCell? {
        switch index {
        case 0:
            let cell = reuseCell(for: .leak)
            cell.setup(
                title: "⚠️ Show Leaks",
                image: .named("chevron.right", default: "Action")
            )
            return cell
        case 1:
            let cell = reuseCell(for: .leak)
            cell.setup(
                title: "🧵 Thread Checker",
                image: .named("chevron.right", default: "Action")
            )
            return cell
        default:
            return nil
        }
    }

    private func configureChartCell(
        _ chartCell: MenuChartTableViewCell,
        value: CGFloat,
        measurements: [CGFloat],
        markedValueFormat: String
    ) {
        chartCell.chartView.maxValue = value
        chartCell.chartView.markedValue = value
        chartCell.chartView.markedValueFormat = markedValueFormat
        chartCell.chartView.measurements = measurements
        chartCell.chartView.measurementsLimit = performanceToolkit.measurementsLimit
        chartCell.chartView.measurementInterval = performanceToolkit.timeBetweenMeasurements
        chartCell.chartView.markedTimesInterval = performanceToolkit.controllerMarked
        
        // Set appropriate colors for different chart types
        switch selectedSection {
        case .cpu:
            chartCell.chartView.chartColor = .systemRed
        case .memory:
            chartCell.chartView.chartColor = .systemOrange
        case .fps:
            chartCell.chartView.chartColor = .systemGreen
        case .leaks:
            chartCell.chartView.chartColor = .systemPurple
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

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.cellForRow(at: indexPath) is MenuChartTableViewCell {
            return tableView.bounds.size.width + chartCellRatioConstant
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let type = Identifier(rawValue: cell?.reuseIdentifier)

        switch type {
        case .memoryWarning:
            handleMemoryWarningTap(cell: cell)
        case .leak:
            // Check which leak-related option was selected
            if selectedSection == .leaks {
                switch indexPath.row {
                case 0:
                    // Show Leaks
                    let viewModel = LeaksViewModel()
                    let controller = ResourcesGenericController(viewModel: viewModel)
                    navigationController?.pushViewController(controller, animated: true)
                case 1:
                    // Thread Checker
                    let threadCheckerController = PerformanceThreadCheckerViewController()
                    navigationController?.pushViewController(threadCheckerController, animated: true)
                default:
                    break
                }
            }
        default:
            break
        }
    }

    // MARK: - Memory Warning Handling
    
    private func handleMemoryWarningTap(cell: UITableViewCell?) {
        // If already simulating, offer to stop
        if memoryWarningSimulator.isCurrentlySimulating {
            showStopSimulationAlert()
            return
        }
        
        // Animate button tap
        cell?.simulateButtonTap()
        
        // Show confirmation alert
        showMemoryWarningConfirmation()
    }
    
    private func showMemoryWarningConfirmation() {
        let alert = UIAlertController(
            title: "🚨 Simulate Memory Warning",
            message: "This will trigger a memory warning throughout your app and simulate memory pressure. This helps test how your app handles low memory conditions.\n\n⚠️ May cause temporary app slowdown.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "🚀 Simulate Now", style: .default) { [weak self] _ in
            self?.executeMemoryWarningSimulation()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showStopSimulationAlert() {
        let alert = UIAlertController(
            title: "Stop Memory Simulation?",
            message: "A memory warning simulation is currently running. Do you want to stop it?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "🛑 Stop Simulation", style: .destructive) { [weak self] _ in
            self?.memoryWarningSimulator.stopSimulation()
            self?.tableView.reloadData() // Refresh UI state
        })
        
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func executeMemoryWarningSimulation() {
        // Update UI immediately
        tableView.reloadData()
        
        // Generate the memory warning
        memoryWarningSimulator.generate()
        
        // Show success feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showSimulationStartedFeedback()
        }
        
        // Auto-refresh UI after simulation completes (about 5 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func showSimulationStartedFeedback() {
        // Create a subtle toast-like notification
        let banner = UIView()
        banner.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        banner.layer.cornerRadius = 8
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "✅ Memory Warning Simulation Started"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        banner.addSubview(label)
        view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            banner.heightAnchor.constraint(equalToConstant: 40),
            
            label.centerXAnchor.constraint(equalTo: banner.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: banner.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: banner.trailingAnchor, constant: -16)
        ])
        
        // Animate in
        banner.alpha = 0
        banner.transform = CGAffineTransform(translationX: 0, y: -20)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            banner.alpha = 1
            banner.transform = .identity
        }) { _ in
            // Animate out after 2 seconds
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseIn, animations: {
                banner.alpha = 0
                banner.transform = CGAffineTransform(translationX: 0, y: -20)
            }) { _ in
                banner.removeFromSuperview()
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch PerformanceTableViewSection(rawValue: section)! {
        case .toggle, .segmentedControl:
            return 1
        case .statistics:
            return numberOfRowsInStatisticsSection()
        }
    }

    override func numberOfSections(in _: UITableView) -> Int {
        3
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        switch indexPath.section {
        case PerformanceTableViewSection.toggle.rawValue:
            return toggleCell()
        case PerformanceTableViewSection.segmentedControl.rawValue:
            return segmentedControlCell() ?? UITableViewCell()
        case PerformanceTableViewSection.statistics.rawValue:
            return statisticsCellForRow(at: indexPath.row) ?? UITableViewCell()
        default:
            return UITableViewCell()
        }
    }

    private func toggleCell() -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: MenuSwitchTableViewCell.identifier
            ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = "Show widget"
        cell.valueSwitch.isOn = performanceToolkit.isWidgetShown
        cell.delegate = self
        return cell
    }

    private func segmentedControlCell() -> UITableViewCell? {
        guard let cell = reuseCell(for: .segmentedControl) as? MenuSegmentedControlTableViewCell else { return nil }
        var segmentTitles = [
            "CPU",
            "Memory",
            "FPS"
        ]

        if !DebugSwift.App.shared.disableMethods.contains(.leaksDetector) {
            segmentTitles.append("Leaks")
        }

        cell.configure(with: segmentTitles, selectedIndex: selectedSection.rawValue)
        cell.delegate = self
        return cell
    }
}

// MARK: - MenuSwitchTableViewCellDelegate

extension PerformanceViewController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(
        _: MenuSwitchTableViewCell, didSetOn isOn: Bool
    ) {
        performanceToolkit.isWidgetShown = isOn
    }
}

// MARK: - MenuSegmentedControlTableViewCellDelegate

extension PerformanceViewController: MenuSegmentedControlTableViewCellDelegate {
    func menuSegmentedControlTableViewCell(
        _: MenuSegmentedControlTableViewCell,
        didSelectSegmentAtIndex index: Int
    ) {
        setSelectedSection(PerformanceSection(rawValue: index)!)
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
}

// MARK: - PerformanceToolkitDelegate

extension PerformanceViewController {
    func performanceToolkitDidUpdateStats(_: PerformanceToolkit) {
        reloadStatisticsSection(animated: false)
    }
}

extension PerformanceViewController: PerformanceWidgetViewDelegate {
    func performanceWidgetView(
        _: PerformanceWidgetView, didTapOnSection _: PerformanceSection
    ) {}
}
