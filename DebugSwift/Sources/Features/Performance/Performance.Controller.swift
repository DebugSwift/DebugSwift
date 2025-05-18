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
            cell.textLabel?.text = "Simulate memory warning"
            cell.contentView.backgroundColor = .systemBlue
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
            let cell = reuseCell()
            cell.textLabel?.text = "All Leaks"
            cell.detailTextLabel?.text = "\(PerformanceLeakDetector.leaks.count)"
            return cell
        case 1:
            let cell = reuseCell(for: .leak)
            cell.setup(
                title: "⚠️ Show Leaks",
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
            cell?.simulateButtonTap()
            PerformanceMemoryWarning().generate()
        case .leak:
            let viewModel = LeaksViewModel()
            let controller = ResourcesGenericController(viewModel: viewModel)
            navigationController?.pushViewController(controller, animated: true)
        default:
            break
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
