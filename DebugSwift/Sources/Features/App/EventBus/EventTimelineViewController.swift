//
//  EventTimelineViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois (Event Timeline) on 16/07/26.
//

import UIKit

/// Displays the live stream of debug events collected by `EventBusSubscriber`,
/// with a domain filter and a clear action so the timeline can be inspected
/// while exercising other debug features.
final class EventTimelineViewController: BaseTableController {

    // MARK: - Properties

    private let subscriber = EventBusSubscriber.shared

    /// Currently displayed events, kept in sync with the bus and filtered by
    /// the active segmented-control selection.
    private var displayedEvents: [DebugEvent] = []

    private lazy var filterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: Filter.allTitles)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        return control
    }()

    private lazy var clearButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearEvents)
        )
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        subscribeToBus()
        refreshDisplayedEvents()
    }

    // MARK: - Setup

    private func setup() {
        title = "Event Timeline"
        navigationItem.rightBarButtonItem = clearButton
        navigationItem.titleView = filterControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
    }

    /// Reload from the bus on every publish so the timeline stays current
    /// without a manual refresh while other features publish into the bus.
    private func subscribeToBus() {
        subscriber.subscribe { [weak self] _ in
            DispatchQueue.main.async { self?.refreshDisplayedEvents() }
        }
    }

    private func refreshDisplayedEvents() {
        let all = subscriber.bus.events
        let selected = Filter(rawValue: filterControl.selectedSegmentIndex) ?? .all
        displayedEvents = selected.filter(all)
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func filterChanged() {
        refreshDisplayedEvents()
    }

    @objc private func clearEvents() {
        subscriber.bus.clear()
        displayedEvents = []
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        displayedEvents.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        let event = displayedEvents[indexPath.row]
        configure(cell, with: event)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    // MARK: - Cell configuration

    private func configure(_ cell: UITableViewCell, with event: DebugEvent) {
        let badge = badgeView(for: event.domain)
        let timeLabel = UILabel()
        timeLabel.text = formatted(timestamp: event.timestamp)
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .lightGray

        let summaryLabel = UILabel()
        summaryLabel.text = event.summary
        summaryLabel.font = .systemFont(ofSize: 15)
        summaryLabel.textColor = .white
        summaryLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [timeLabel, badge, summaryLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.tag = 111

        cell.contentView.subviews.filter { $0.tag == 111 }.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
        ])

        cell.backgroundColor = .clear
        cell.selectionStyle = .none
    }

    /// Compact colored pill identifying the event's domain at a glance.
    private func badgeView(for domain: DebugDomain) -> UIView {
        let label = UILabel()
        label.text = domain.rawValue.capitalized
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = color(for: domain).withAlphaComponent(0.25)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.heightAnchor.constraint(equalToConstant: 18),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),
        ])
        return container
    }

    private func formatted(timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    /// Stable color per domain so the same domain is always the same tint.
    private func color(for domain: DebugDomain) -> UIColor {
        switch domain {
        case .network: return .systemBlue
        case .performance: return .systemOrange
        case .interface: return .systemPurple
        case .app: return .systemTeal
        case .resources: return .systemIndigo
        case .security: return .systemRed
        }
    }
}

// MARK: - Filter

private extension EventTimelineViewController {

    /// Segmented-control index mapped to a domain filter; `all` leaves the list
    /// unfiltered so every event across domains is visible.
    enum Filter: Int, CaseIterable {
        case all
        case network
        case performance
        case interface
        case app
        case resources
        case security

        static var allTitles: [String] {
            ["All", "Network", "Performance", "Interface", "App", "Resources", "Security"]
        }

        func filter(_ events: [DebugEvent]) -> [DebugEvent] {
            guard let domain = self.domain else { return events }
            return events.filter { $0.domain == domain }
        }

        private var domain: DebugDomain? {
            switch self {
            case .all: return nil
            case .network: return .network
            case .performance: return .performance
            case .interface: return .interface
            case .app: return .app
            case .resources: return .resources
            case .security: return .security
            }
        }
    }
}
