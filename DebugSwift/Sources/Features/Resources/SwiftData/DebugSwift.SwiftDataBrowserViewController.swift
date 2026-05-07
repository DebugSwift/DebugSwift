//
//  DebugSwift.SwiftDataBrowserViewController.swift
//  DebugSwift
//
//  Root browser — lists all registered SwiftData models grouped by container.
//

import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataBrowserViewController: BaseController {

    // MARK: - Properties

    private var registrations: [SwiftDataContextRegistration] = []
    private var filteredRegistrations: [SwiftDataContextRegistration] = []
    private var selectedRegistration: SwiftDataContextRegistration?

    private var searchController: UISearchController!

    private lazy var contextSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(contextChanged), for: .valueChanged)
        return control
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(SwiftDataModelCell.self, forCellReuseIdentifier: "ModelCell")
        return table
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "No SwiftData containers configured.\n\nUse:\nDebugSwift.Resources.shared\n  .configureSwiftData(contexts:)"
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ImpactFeedback.generate()
    }
}

// MARK: - Setup

private extension SwiftDataBrowserViewController {

    func setup() {
        setupViews()
        setupNavigation()
        setupSearchController()
    }

    func setupViews() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupNavigation() {
        title = "SwiftData Browser"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
    }

    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search models"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    func setupSegmentedControl() {
        guard registrations.count > 1 else {
            tableView.tableHeaderView = nil
            return
        }

        contextSegmentedControl.removeAllSegments()
        for (index, reg) in registrations.enumerated() {
            contextSegmentedControl.insertSegment(withTitle: reg.name, at: index, animated: false)
        }
        contextSegmentedControl.selectedSegmentIndex = 0

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contextSegmentedControl)

        NSLayoutConstraint.activate([
            contextSegmentedControl.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            contextSegmentedControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            contextSegmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            contextSegmentedControl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            container.heightAnchor.constraint(equalToConstant: 60)
        ])

        tableView.tableHeaderView = container
    }

    // MARK: - Actions

    @objc func contextChanged() {
        let index = contextSegmentedControl.selectedSegmentIndex
        guard index >= 0, index < registrations.count else { return }
        selectedRegistration = registrations[index]
        applyFilter()
    }

    @objc func refreshData() {
        loadData()
    }

    // MARK: - Data

    func loadData() {
        registrations = SwiftDataManager.shared.getAvailableContexts()
        selectedRegistration = SwiftDataManager.shared.getDefaultContext()

        if registrations.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
            setupSegmentedControl()
            applyFilter()
        }
    }

    func applyFilter() {
        guard let selected = selectedRegistration else {
            filteredRegistrations = []
            tableView.reloadData()
            return
        }

        let searchText = searchController.searchBar.text ?? ""
        if searchText.isEmpty {
            filteredRegistrations = [selected]
        } else {
            let filtered = selected.models.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
            filteredRegistrations = filtered.isEmpty ? [] : [
                SwiftDataContextRegistration(
                    name: selected.name,
                    container: selected.container,
                    models: filtered
                )
            ]
        }

        tableView.reloadData()
        updateEmptyState()
    }

    // MARK: - Empty State

    func showEmptyState() {
        tableView.backgroundView = emptyStateLabel
        tableView.separatorStyle = .none
    }

    func hideEmptyState() {
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
    }

    func updateEmptyState() {
        guard let selected = selectedRegistration else {
            showEmptyState()
            return
        }
        let visibleModels = filteredRegistrations.first?.models ?? []
        if visibleModels.isEmpty {
            emptyStateLabel.text = selected.models.isEmpty
                ? "No models registered in this container."
                : "No results for \"\(searchController.searchBar.text ?? "")\"."
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }
}

// MARK: - UITableViewDataSource

extension SwiftDataBrowserViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredRegistrations.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRegistrations[section].models.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard filteredRegistrations.count > 1 else { return nil }
        return filteredRegistrations[section].name
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModelCell", for: indexPath) as! SwiftDataModelCell
        let reg = filteredRegistrations[indexPath.section]
        let model = reg.models[indexPath.row]
        let context = ModelContext(reg.container)
        let count = (try? SwiftDataManager.shared.fetchInstances(registration: model, context: context).count) ?? 0
        cell.configure(name: model.displayName, count: count)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SwiftDataBrowserViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let reg = filteredRegistrations[indexPath.section]
        let model = reg.models[indexPath.row]
        let instancesVC = SwiftDataInstancesViewController(
            modelRegistration: model,
            container: reg.container
        )
        navigationController?.pushViewController(instancesVC, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension SwiftDataBrowserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}

// MARK: - Model Cell

final class SwiftDataModelCell: UITableViewCell {

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemPurple
        iv.image = UIImage(systemName: "tray.full.fill")
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .medium)
        return l
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        accessoryType = .disclosureIndicator
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            countLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
        ])
    }

    func configure(name: String, count: Int) {
        nameLabel.text = name
        countLabel.text = "\(count) \(count == 1 ? "instance" : "instances")"
    }
}

#endif
