//
//  DebugSwift.SwiftDataInstancesViewController.swift
//  DebugSwift
//
//  Lists all instances of a registered SwiftData model.
//

import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataInstancesViewController: BaseController {

    // MARK: - Properties

    private let modelRegistration: SwiftDataModelRegistration
    private let container: ModelContainer
    private var context: ModelContext

    private var instances: [any PersistentModel] = []
    private var filteredInstances: [any PersistentModel] = []
    private var allProperties: [(label: String, value: String)] = []

    private var searchController: UISearchController!

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(SwiftDataInstanceCell.self, forCellReuseIdentifier: "InstanceCell")
        return table
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        return label
    }()

    // MARK: - Init

    init(modelRegistration: SwiftDataModelRegistration, container: ModelContainer) {
        self.modelRegistration = modelRegistration
        self.container = container
        self.context = ModelContext(container)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadInstances()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadInstances()
    }
}

// MARK: - Setup

private extension SwiftDataInstancesViewController {

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
        title = modelRegistration.displayName
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
        searchController.searchBar.placeholder = "Search instances"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    @objc func refreshData() {
        // Rebuild context for fresh data
        context = ModelContext(container)
        loadInstances()
    }

    // MARK: - Data

    func loadInstances() {
        do {
            instances = try SwiftDataManager.shared.fetchInstances(
                registration: modelRegistration,
                context: context
            )
        } catch {
            instances = []
            showError(error)
        }
        applyFilter()
    }

    func applyFilter() {
        let searchText = searchController.searchBar.text ?? ""
        if searchText.isEmpty {
            filteredInstances = instances
        } else {
            filteredInstances = instances.filter { model in
                let props = SwiftDataManager.shared.properties(of: model)
                return props.contains { prop in
                    prop.label.localizedCaseInsensitiveContains(searchText) ||
                    prop.value.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        tableView.reloadData()
        updateEmptyState()
    }

    // MARK: - Empty State

    func updateEmptyState() {
        if filteredInstances.isEmpty {
            emptyStateLabel.text = instances.isEmpty
                ? "No instances found in this model."
                : "No results for \"\(searchController.searchBar.text ?? "")\"."
            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SwiftDataInstancesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredInstances.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        filteredInstances.isEmpty ? nil : "Instances (\(filteredInstances.count))"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InstanceCell", for: indexPath) as! SwiftDataInstanceCell
        let model = filteredInstances[indexPath.row]
        let props = SwiftDataManager.shared.properties(of: model)
        cell.configure(index: indexPath.row + 1, properties: props)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SwiftDataInstancesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = filteredInstances[indexPath.row]
        let detailVC = SwiftDataInstanceDetailViewController(
            model: model,
            modelRegistration: modelRegistration,
            context: context
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard !SwiftDataManager.shared.readOnlyMode else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteInstance(at: indexPath, completion: completion)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func deleteInstance(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let model = filteredInstances[indexPath.row]

        let alert = UIAlertController(
            title: "Delete Instance",
            message: "Are you sure? This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { completion(false); return }
            do {
                try SwiftDataManager.shared.deleteInstance(
                    model,
                    registration: self.modelRegistration,
                    context: self.context
                )
                self.loadInstances()
                completion(true)
            } catch {
                self.showError(error)
                completion(false)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
        present(alert, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension SwiftDataInstancesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}

// MARK: - Instance Cell

final class SwiftDataInstanceCell: UITableViewCell {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.numberOfLines = 2
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 3
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        accessoryType = .disclosureIndicator
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(index: Int, properties: [(label: String, value: String)]) {
        let preview = properties.prefix(3)
        let lines = preview.map { "\($0.label): \($0.value)" }
        titleLabel.text = lines.first ?? "Instance \(index)"
        subtitleLabel.text = lines.dropFirst().joined(separator: "\n")
    }
}

#endif
