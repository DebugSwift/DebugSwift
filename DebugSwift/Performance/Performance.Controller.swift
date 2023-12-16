//
//  PerformanceViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit

class PerformanceViewController: BaseTableController, PerformanceToolkitDelegate {

    var selectedSection: PerformanceSection = .CPU
    lazy var performanceToolkit = PerformanceToolkit(widgetDelegate: self)

    private let segmentedControlCellIdentifier = "MenuSegmentedControlTableViewCell"
    private let valueCellIdentifier = "MenuValueTableViewCell"
    private let buttonCellIdentifier = "MenuButtonTableViewCell"
    private let chartCellIdentifier = "MenuChartTableViewCell"
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
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        performanceToolkit.delegate = self
    }

    // MARK: - Setup Methods

    private func setup() {
        title = "Performance"
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "speedometer"),
            tag: 1
        )
    }

    private func setupTableView() {
        tableView.register(
            MenuSwitchTableViewCell.self,
            forCellReuseIdentifier: MenuSwitchTableViewCell.identifier
        )
        tableView.register(MenuSegmentedControlTableViewCell.self, forCellReuseIdentifier: segmentedControlCellIdentifier)
        tableView.register(MenuChartTableViewCell.self, forCellReuseIdentifier: chartCellIdentifier)
        tableView.backgroundColor = .black
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
        let segmentedControlIndexPath = IndexPath(row: 0, section: PerformanceTableViewSection.segmentedControl.rawValue)
        if let segmentedControlCell = tableView.cellForRow(at: segmentedControlIndexPath) as? MenuSegmentedControlTableViewCell {
            segmentedControlCell.segmentedControl.selectedSegmentIndex = selectedSection.rawValue
        }
    }

    // MARK: - Statistics section

    func numberOfRowsInStatisticsSection() -> Int {
        switch selectedSection {
        case .CPU, .FPS:
            return 3
        case .Memory:
            return 4
        }
    }

    func statisticsCellForRow(at index: Int) -> UITableViewCell? {
        switch selectedSection {
        case .CPU:
            return cpuStatisticsCellForRow(at: index)
        case .Memory:
            return memoryStatisticsCellForRow(at: index)
        case .FPS:
            return fpsStatisticsCellForRow(at: index)
        }
    }

    func cpuStatisticsCellForRow(at index: Int) -> UITableViewCell? {
        switch index {
        case 0:
            let cell = valueTableViewCell()
            cell.textLabel?.text = "CPU usage"
            cell.detailTextLabel?.text = String(format: "%.1lf%%", performanceToolkit.currentCPU)
            return cell
        case 1:
            let cell = valueTableViewCell()
            cell.textLabel?.text = "Max CPU usage"
            cell.detailTextLabel?.text = String(format: "%.1lf%%", performanceToolkit.maxCPU)
            return cell
        case 2:
            guard let chartCell = tableView.dequeueReusableCell(withIdentifier: chartCellIdentifier) as? MenuChartTableViewCell else { return nil }
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
            let cell = valueTableViewCell()
            cell.textLabel?.text = "Memory usage"
            cell.detailTextLabel?.text = String(format: "%.1lf MB", performanceToolkit.currentMemory)
            return cell
        case 1:
            let cell = valueTableViewCell()
            cell.textLabel?.text = "Max memory usage"
            cell.detailTextLabel?.text = String(format: "%.1lf MB", performanceToolkit.maxMemory)
            return cell
        case 2:
            guard let chartCell = tableView.dequeueReusableCell(withIdentifier: chartCellIdentifier) as? MenuChartTableViewCell else { return nil }
            configureChartCell(
                chartCell,
                value: performanceToolkit.maxMemory,
                measurements: performanceToolkit.memoryMeasurements,
                markedValueFormat: "%.1lf MB"
            )
            return chartCell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: buttonCellIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: buttonCellIdentifier)
            cell.textLabel?.text = "Simulate memory warning"
            return cell
        default:
            return nil
        }
    }

    func fpsStatisticsCellForRow(at index: Int) -> UITableViewCell? {
        let cell = valueTableViewCell()

        switch index {
        case 0:
            cell.textLabel?.text = "FPS"
            cell.detailTextLabel?.text = String(format: "%.0lf", performanceToolkit.currentFPS)
        case 1:
            cell.textLabel?.text = "Min FPS"
            cell.detailTextLabel?.text = String(format: "%.0lf", performanceToolkit.minFPS)
        case 2:
            guard let chartCell = tableView.dequeueReusableCell(withIdentifier: chartCellIdentifier) as? MenuChartTableViewCell else { return nil }
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
    }

    private func valueTableViewCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: valueCellIdentifier) ?? UITableViewCell(style: .value1, reuseIdentifier: valueCellIdentifier)
        cell.selectionStyle = .none
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == PerformanceTableViewSection.statistics.rawValue && indexPath.row == 2 {
            // Chart cell.
            return tableView.bounds.size.width + chartCellRatioConstant
        }
        return 44.0
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch PerformanceTableViewSection(rawValue: section)! {
        case .toggle, .segmentedControl:
            return 1
        case .statistics:
            return numberOfRowsInStatisticsSection()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case PerformanceTableViewSection.toggle.rawValue:
            return toggleCell()
        case PerformanceTableViewSection.segmentedControl.rawValue:
            return segmentedControlCell()
        case PerformanceTableViewSection.statistics.rawValue:
            return statisticsCellForRow(at: indexPath.row) ?? UITableViewCell()
        default:
            return UITableViewCell()
        }
    }

    private func toggleCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuSwitchTableViewCell.identifier
        ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = "Show widget"
        cell.valueSwitch.isOn = performanceToolkit.isWidgetShown
        cell.delegate = self
        return cell
    }

    private func segmentedControlCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: segmentedControlCellIdentifier) as? MenuSegmentedControlTableViewCell ?? MenuSegmentedControlTableViewCell()
        let segmentTitles = ["CPU", "Memory", "FPS"]
        cell.configure(with: segmentTitles, selectedIndex: selectedSection.rawValue)
        cell.delegate = self
        return cell
    }
}

// MARK: - MenuSwitchTableViewCellDelegate

extension PerformanceViewController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(_ menuSwitchTableViewCell: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        performanceToolkit.isWidgetShown = isOn
    }
}

// MARK: - MenuSegmentedControlTableViewCellDelegate

extension PerformanceViewController: MenuSegmentedControlTableViewCellDelegate {
    func menuSegmentedControlTableViewCell(_ menuSegmentedControlTableViewCell: MenuSegmentedControlTableViewCell, didSelectSegmentAtIndex index: Int) {
        setSelectedSection(PerformanceSection(rawValue: index)!)
    }
}

// MARK: - PerformanceToolkitDelegate

extension PerformanceViewController {
    func performanceToolkitDidUpdateStats(_ performanceToolkit: PerformanceToolkit) {
        reloadStatisticsSection(animated: false)
    }
}

extension PerformanceViewController: PerformanceWidgetViewDelegate {
    func performanceWidgetView(_ performanceWidgetView: PerformanceWidgetView, didTapOnSection section: PerformanceSection) {

    }
}
