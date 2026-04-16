//
//  SwiftDataBrowserViewController.swift
//  DebugSwift
//
//  Lists registered SwiftData contexts and models
//

import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataBrowserViewController: BaseController {
    private var contexts: [SwiftDataContextRegistration] = []
    private var selectedContext: SwiftDataContextRegistration?
    private var entities: [SwiftDataEntity] = []
    private var filteredEntities: [SwiftDataEntity] = []

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
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SwiftDataEntityCell")
        return table
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "No SwiftData containers configured.\n\nUse DebugSwift.Resources.shared.configureSwiftData(contexts:) to setup."
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadData()
    }
}

@available(iOS 17.0, *)
private extension SwiftDataBrowserViewController {
    func setup() {
        title = "SwiftData Browser"

        setupViews()
        setupSearchController()
        setupNavigation()
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

    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search models"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
    }

    @objc func refreshData() {
        loadData()
    }

    @objc func contextChanged() {
        let index = contextSegmentedControl.selectedSegmentIndex
        guard index >= 0, index < contexts.count else { return }
        selectedContext = contexts[index]
        loadEntities()
    }

    func loadData() {
        contexts = SwiftDataManager.shared.getAvailableContexts()
        selectedContext = SwiftDataManager.shared.getDefaultContext()

        if contexts.isEmpty {
            showEmptyState()
            return
        }

        hideEmptyState()
        setupContextSegmentedControl()
        loadEntities()
    }

    func setupContextSegmentedControl() {
        guard contexts.count > 1 else {
            tableView.tableHeaderView = nil
            return
        }

        contextSegmentedControl.removeAllSegments()
        for (index, context) in contexts.enumerated() {
            contextSegmentedControl.insertSegment(withTitle: context.name, at: index, animated: false)
        }

        let selectedIndex = contexts.firstIndex { context in
            context.name == selectedContext?.name
        } ?? 0
        contextSegmentedControl.selectedSegmentIndex = selectedIndex

        let containerView = UIView()
        containerView.addSubview(contextSegmentedControl)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contextSegmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            contextSegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contextSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contextSegmentedControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            containerView.heightAnchor.constraint(equalToConstant: 60)
        ])

        tableView.tableHeaderView = containerView
        tableView.tableHeaderView?.frame.size.height = 60
    }

    func loadEntities() {
        guard let selectedContext else {
            entities = []
            filteredEntities = []
            tableView.reloadData()
            return
        }

        entities = SwiftDataManager.shared.getEntities(for: selectedContext)
        applyFilter()
    }

    func applyFilter() {
        let searchText = searchController.searchBar.text ?? ""
        if searchText.isEmpty {
            filteredEntities = entities
        } else {
            filteredEntities = entities.filter { entity in
                entity.displayName.localizedCaseInsensitiveContains(searchText) ||
                    entity.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        tableView.reloadData()
        updateEmptyState()
    }

    func showEmptyState() {
        tableView.backgroundView = emptyStateLabel
        tableView.separatorStyle = .none
    }

    func hideEmptyState() {
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
    }

    func updateEmptyState() {
        if filteredEntities.isEmpty {
            emptyStateLabel.text = "No models found."
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }
}

@available(iOS 17.0, *)
extension SwiftDataBrowserViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return selectedContext == nil ? 0 : 1
        }
        return filteredEntities.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Container Inspector"
        }
        return filteredEntities.isEmpty ? nil : "Models (\(filteredEntities.count))"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwiftDataEntityCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        if indexPath.section == 0 {
            guard let selectedContext else {
                return cell
            }
            let context = selectedContext.container.mainContext
            content.text = selectedContext.name
            content.secondaryText = "Entities: \(selectedContext.container.schema.entities.count) | Autosave: \(context.autosaveEnabled ? "On" : "Off") | Has Changes: \(context.hasChanges ? "Yes" : "No")"
            content.image = UIImage(systemName: "shippingbox")
            cell.accessoryType = .none
        } else {
            let entity = filteredEntities[indexPath.row]
            content.text = entity.displayName
            content.secondaryText = "\(entity.objectCount) objects" + (entity.isBrowsable ? "" : " • register model to browse rows")
            content.image = UIImage(systemName: entity.isBrowsable ? "square.stack.3d.up.fill" : "exclamationmark.triangle")
            cell.accessoryType = entity.isBrowsable ? .disclosureIndicator : .none
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section == 1 else { return }
        guard let selectedContext else { return }

        let entity = filteredEntities[indexPath.row]
        guard entity.isBrowsable else { return }

        let controller = SwiftDataEntityViewController(
            registration: selectedContext,
            entityName: entity.name,
            titleText: entity.displayName
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 64 : 80
    }
}

@available(iOS 17.0, *)
extension SwiftDataBrowserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}

#endif
