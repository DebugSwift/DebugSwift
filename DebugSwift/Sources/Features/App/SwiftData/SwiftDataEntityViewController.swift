//
//  SwiftDataEntityViewController.swift
//  DebugSwift
//
//  Lists model instances and allows inspection/editing
//

import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataEntityViewController: BaseController {
    private let registration: SwiftDataContextRegistration
    private let entityName: String

    private var models: [any PersistentModel] = []
    private var filteredModels: [any PersistentModel] = []

    private var searchController: UISearchController!

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SwiftDataModelCell")
        return table
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "No model instances found."
        return label
    }()

    init(
        registration: SwiftDataContextRegistration,
        entityName: String,
        titleText: String
    ) {
        self.registration = registration
        self.entityName = entityName
        super.init()
        title = titleText
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadModels()
    }
}

@available(iOS 17.0, *)
private extension SwiftDataEntityViewController {
    func setup() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupSearchController()
        setupNavigation()
    }

    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search values"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    func setupNavigation() {
        var buttons: [UIBarButtonItem] = [
            UIBarButtonItem(
                barButtonSystemItem: .refresh,
                target: self,
                action: #selector(refreshData)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(exportData)
            )
        ]

        if canCreate {
            buttons.append(
                UIBarButtonItem(
                    barButtonSystemItem: .add,
                    target: self,
                    action: #selector(addModel)
                )
            )
        }

        navigationItem.rightBarButtonItems = buttons
    }

    var canCreate: Bool {
        let normalizedEntityName = normalizeEntityName(entityName)
        return registration.models.contains { model in
            model.create != nil && normalizeEntityName(model.entityName) == normalizedEntityName
        } && !DebugSwift.Resources.shared.swiftDataReadOnly
    }

    func normalizeEntityName(_ name: String) -> String {
        name.split(separator: ".").last.map(String.init) ?? name
    }

    @objc func refreshData() {
        loadModels()
    }

    @objc func exportData() {
        do {
            let json = try SwiftDataManager.shared.exportAsJSON(
                entityName: entityName,
                in: registration
            )

            let activity = UIActivityViewController(activityItems: [json], applicationActivities: nil)
            present(activity, animated: true)
        } catch {
            showError(error)
        }
    }

    @objc func addModel() {
        do {
            try SwiftDataManager.shared.createModel(entityName: entityName, in: registration)
            loadModels()
        } catch {
            showError(error)
        }
    }

    func loadModels() {
        do {
            models = try SwiftDataManager.shared.fetchModels(entityName: entityName, in: registration)
            applyFilter()
        } catch {
            models = []
            filteredModels = []
            tableView.reloadData()
            showError(error)
        }
    }

    func applyFilter() {
        let text = searchController.searchBar.text ?? ""
        if text.isEmpty {
            filteredModels = models
        } else {
            filteredModels = models.filter { model in
                SwiftDataManager.shared.makeSummary(for: model).localizedCaseInsensitiveContains(text) ||
                    String(describing: model).localizedCaseInsensitiveContains(text)
            }
        }
        tableView.reloadData()
        updateEmptyState()
    }

    func updateEmptyState() {
        if filteredModels.isEmpty {
            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

    func deleteModel(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let model = filteredModels[indexPath.row]

        let alert = UIAlertController(
            title: "Delete Model",
            message: "This action cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else {
                completion(false)
                return
            }
            do {
                try SwiftDataManager.shared.deleteModel(
                    model,
                    entityName: self.entityName,
                    in: self.registration
                )
                self.loadModels()
                completion(true)
            } catch {
                self.showError(error)
                completion(false)
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })

        present(alert, animated: true)
    }

    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "SwiftData Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

@available(iOS 17.0, *)
extension SwiftDataEntityViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwiftDataModelCell", for: indexPath)
        let model = filteredModels[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = SwiftDataManager.shared.makeSummary(for: model)
        content.secondaryText = String(describing: model)
        content.secondaryTextProperties.numberOfLines = 2
        content.image = UIImage(systemName: "doc.text.magnifyingglass")

        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let model = filteredModels[indexPath.row]
        let controller = SwiftDataModelDetailViewController(
            registration: registration,
            entityName: entityName,
            model: model
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        filteredModels.isEmpty ? nil : "Instances (\(filteredModels.count))"
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard !DebugSwift.Resources.shared.swiftDataReadOnly else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteModel(at: indexPath, completion: completion)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

@available(iOS 17.0, *)
extension SwiftDataEntityViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}

@available(iOS 17.0, *)
@MainActor
final class SwiftDataModelDetailViewController: BaseTableController {
    private let registration: SwiftDataContextRegistration
    private let entityName: String
    private let model: any PersistentModel
    private var properties: [SwiftDataPropertyItem] = []

    init(
        registration: SwiftDataContextRegistration,
        entityName: String,
        model: any PersistentModel
    ) {
        self.registration = registration
        self.entityName = entityName
        self.model = model
        super.init()
        title = entityName
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SwiftDataPropertyCell")
        loadProperties()
    }

    private func loadProperties() {
        properties = SwiftDataManager.shared.getProperties(
            for: model,
            entityName: entityName,
            in: registration
        )
        tableView.reloadData()
    }

    private func editable(_ property: SwiftDataPropertyItem) -> Bool {
        !DebugSwift.Resources.shared.swiftDataReadOnly &&
            property.isAttribute &&
            !property.isRelationship &&
            property.rawValue != nil &&
            model is NSObject
    }

    private func presentEditAlert(for property: SwiftDataPropertyItem) {
        guard editable(property) else { return }

        let alert = UIAlertController(
            title: "Edit \(property.name)",
            message: "Current: \(property.valueDescription)",
            preferredStyle: .alert
        )

        alert.addTextField { field in
            field.text = property.valueDescription == "nil" ? "" : property.valueDescription
            field.placeholder = "New value"
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }
            let value = alert.textFields?.first?.text ?? ""
            do {
                try SwiftDataManager.shared.updateProperty(
                    model: self.model,
                    entityName: self.entityName,
                    propertyName: property.name,
                    newValueText: value,
                    in: self.registration
                )
                self.loadProperties()
            } catch {
                self.showError(error)
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Update Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

@available(iOS 17.0, *)
extension SwiftDataModelDetailViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return properties.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Model" : "Properties (\(properties.count))"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwiftDataPropertyCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        if indexPath.section == 0 {
            content.text = String(describing: model)
            content.secondaryText = "Tap an editable property below to modify and save."
            content.secondaryTextProperties.numberOfLines = 2
            content.image = UIImage(systemName: "shippingbox.circle")
            cell.accessoryType = .none
        } else {
            let property = properties[indexPath.row]
            var metadata: [String] = [property.typeName]
            if property.isRelationship { metadata.append("relationship") }
            if property.isOptional { metadata.append("optional") }
            if property.isTransient { metadata.append("transient") }
            if property.isUnique { metadata.append("unique") }

            content.text = "\(property.name): \(property.valueDescription)"
            content.secondaryText = metadata.joined(separator: " • ")
            content.secondaryTextProperties.numberOfLines = 2
            content.image = UIImage(systemName: property.isRelationship ? "link" : "slider.horizontal.3")
            cell.accessoryType = editable(property) ? .detailButton : .none
        }

        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        presentEditAlert(for: properties[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        presentEditAlert(for: properties[indexPath.row])
    }
}

#endif
