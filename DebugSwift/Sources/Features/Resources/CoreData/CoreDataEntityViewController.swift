//
//  CoreDataEntityViewController.swift
//  DebugSwift
//
//  View controller for displaying list of managed objects in an entity
//

import UIKit
import CoreData

@MainActor
final class CoreDataEntityViewController: BaseController {
    
    // MARK: - Properties
    
    private let entity: CoreDataEntity
    private let context: NSManagedObjectContext
    private var objects: [NSManagedObject] = []
    private var filteredObjects: [NSManagedObject] = []
    
    private var searchController: UISearchController!
    private var sortDescriptors: [NSSortDescriptor] = []
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(CoreDataObjectCell.self, forCellReuseIdentifier: "ObjectCell")
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
    
    // MARK: - Initialization
    
    init(entity: CoreDataEntity, context: NSManagedObjectContext) {
        self.entity = entity
        self.context = context
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadObjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadObjects()
    }
}

// MARK: - Setup

private extension CoreDataEntityViewController {
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
        title = entity.name
        
        let refreshButton = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
        
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(showSortOptions)
        )
        
        navigationItem.rightBarButtonItems = [refreshButton, sortButton]
    }
    
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by attributes"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    @objc func refreshData() {
        loadObjects()
    }
    
    @objc func showSortOptions() {
        let alert = UIAlertController(
            title: "Sort By",
            message: "Select an attribute to sort by",
            preferredStyle: .actionSheet
        )
        
        for attribute in entity.attributes {
            alert.addAction(UIAlertAction(title: "\(attribute.name) ▲", style: .default) { [weak self] _ in
                self?.sortObjects(by: attribute.name, ascending: true)
            })
            alert.addAction(UIAlertAction(title: "\(attribute.name) ▼", style: .default) { [weak self] _ in
                self?.sortObjects(by: attribute.name, ascending: false)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Clear Sort", style: .destructive) { [weak self] _ in
            self?.sortDescriptors = []
            self?.loadObjects()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
    
    func sortObjects(by key: String, ascending: Bool) {
        sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]
        loadObjects()
    }
    
    func loadObjects() {
        objects = CoreDataManager.shared.fetchObjects(
            entityName: entity.name,
            context: context,
            sortDescriptors: sortDescriptors.isEmpty ? nil : sortDescriptors
        )
        applyFilter()
    }
    
    func applyFilter() {
        let searchText = searchController.searchBar.text ?? ""
        
        if searchText.isEmpty {
            filteredObjects = objects
        } else {
            filteredObjects = objects.filter { object in
                for attribute in entity.attributes {
                    if let value = object.value(forKey: attribute.name) {
                        let stringValue = String(describing: value)
                        if stringValue.localizedCaseInsensitiveContains(searchText) {
                            return true
                        }
                    }
                }
                return false
            }
        }
        
        tableView.reloadData()
        updateEmptyState()
    }
    
    func updateEmptyState() {
        if filteredObjects.isEmpty {
            if objects.isEmpty {
                emptyStateLabel.text = "No objects in this entity."
            } else if let text = searchController.searchBar.text, !text.isEmpty {
                emptyStateLabel.text = "No results for \"\(text)\"."
            }
            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
}

// MARK: - UITableViewDataSource

extension CoreDataEntityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredObjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ObjectCell", for: indexPath) as! CoreDataObjectCell
        let object = filteredObjects[indexPath.row]
        cell.configure(with: object, entity: entity)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !filteredObjects.isEmpty else { return nil }
        return "Objects (\(filteredObjects.count))"
    }
}

// MARK: - UITableViewDelegate

extension CoreDataEntityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let object = filteredObjects[indexPath.row]
        let detailVC = CoreDataObjectDetailViewController(
            object: object,
            entity: entity,
            context: context
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !DebugSwift.Resources.shared.coreDataReadOnly else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteObject(at: indexPath, completion: completion)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func deleteObject(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let object = filteredObjects[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Object",
            message: "Are you sure you want to delete this object? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else {
                completion(false)
                return
            }
            
            do {
                try CoreDataManager.shared.deleteObject(object, context: self.context)
                self.loadObjects()
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
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension CoreDataEntityViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}

// MARK: - Object Cell

final class CoreDataObjectCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        accessoryType = .disclosureIndicator
        
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
    
    func configure(with object: NSManagedObject, entity: CoreDataEntity) {
        var titleParts: [String] = []
        var subtitleParts: [String] = []
        
        let displayLimit = 3
        var count = 0
        
        for attribute in entity.attributes.prefix(displayLimit) {
            if let value = object.value(forKey: attribute.name) {
                let stringValue = formatValue(value)
                
                if count == 0 {
                    titleParts.append("\(attribute.name): \(stringValue)")
                } else {
                    subtitleParts.append("\(attribute.name): \(stringValue)")
                }
                count += 1
            }
        }
        
        if titleParts.isEmpty {
            titleLabel.text = "Object ID: \(object.objectID)"
        } else {
            titleLabel.text = titleParts.joined(separator: ", ")
        }
        
        if subtitleParts.isEmpty {
            subtitleLabel.text = "Object ID: \(object.objectID)"
        } else {
            subtitleLabel.text = subtitleParts.joined(separator: "\n")
        }
    }
    
    private func formatValue(_ value: Any) -> String {
        switch value {
        case let date as Date:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        case let data as Data:
            return "\(data.count) bytes"
        case let number as NSNumber:
            return number.stringValue
        case let string as String:
            return string.prefix(50) + (string.count > 50 ? "..." : "")
        default:
            let stringValue = String(describing: value)
            return stringValue.prefix(50) + (stringValue.count > 50 ? "..." : "")
        }
    }
}
