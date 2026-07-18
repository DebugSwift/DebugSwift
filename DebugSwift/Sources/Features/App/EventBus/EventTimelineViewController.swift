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
    /// the active filter selection.
    private var displayedEvents: [DebugEvent] = []

    private var selectedFilter: Filter = .all

    private lazy var clearButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearEvents)
        )
    }()

    private lazy var filterBar: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.reuseId)
        cv.delegate = self
        cv.dataSource = self
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 52))
        headerView.backgroundColor = .black
        headerView.addSubview(filterBar)

        NSLayoutConstraint.activate([
            filterBar.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            filterBar.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            filterBar.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            filterBar.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
        ])

        tableView.tableHeaderView = headerView
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
        displayedEvents = selectedFilter.filter(all)
        tableView.reloadData()
    }

    // MARK: - Actions

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

// MARK: - Filter Collection View

extension EventTimelineViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        Filter.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCell.reuseId, for: indexPath) as? FilterCell else {
            return UICollectionViewCell()
        }
        let filter = Filter.allCases[indexPath.item]
        let isSelected = filter == selectedFilter
        cell.configure(title: filter.title, color: color(for: filter.domain ?? .app), isSelected: isSelected)
        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let filter = Filter.allCases[indexPath.item]
        let text = filter.title
        let width = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]).width + 32
        return CGSize(width: max(width, 60), height: 36)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilter = Filter.allCases[indexPath.item]
        collectionView.reloadData()
        refreshDisplayedEvents()
    }
}

// MARK: - Filter Cell

private final class FilterCell: UICollectionViewCell {
    static let reuseId = "FilterCell"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
        ])
        layer.cornerRadius = 18
        layer.masksToBounds = true
        layer.borderWidth = 1
    }

    func configure(title: String, color: UIColor, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            backgroundColor = color.withAlphaComponent(0.3)
            titleLabel.textColor = .white
            layer.borderColor = color.cgColor
        } else {
            backgroundColor = UIColor.white.withAlphaComponent(0.05)
            titleLabel.textColor = .lightGray
            layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        }
    }
}

// MARK: - Filter

private extension EventTimelineViewController {

    /// Filter option mapped to a domain; `all` leaves the list unfiltered so
    /// every event across domains is visible.
    enum Filter: Int, CaseIterable {
        case all
        case network
        case performance
        case interface
        case app
        case resources
        case security

        var title: String {
            switch self {
            case .all: "All"
            case .network: "Network"
            case .performance: "Performance"
            case .interface: "Interface"
            case .app: "App"
            case .resources: "Resources"
            case .security: "Security"
            }
        }

        var domain: DebugDomain? {
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

        func filter(_ events: [DebugEvent]) -> [DebugEvent] {
            guard let domain else { return events }
            return events.filter { $0.domain == domain }
        }
    }
}
