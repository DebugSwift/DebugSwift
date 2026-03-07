//
//  CoreDataBrowserViewController.swift
//  DebugSwift
//
//  Main browser for Core Data entities and contexts
//

import UIKit
import CoreData

@MainActor
final class CoreDataBrowserViewController: BaseController {
    
    // MARK: - Properties
    
    private var contexts: [(name: String, context: NSManagedObjectContext)] = []
    private var entities: [CoreDataEntity] = []
    private var filteredEntities: [CoreDataEntity] = []
    private var selectedContext: NSManagedObjectContext?
    
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
        table.register(CoreDataEntityCell.self, forCellReuseIdentifier: "EntityCell")
        return table
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "No Core Data stack configured.\n\nUse DebugSwift.Resources.shared.configureCoreData() to setup."
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

private extension CoreDataBrowserViewController {
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
        title = "Core Data Browser"
        
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
        searchController.searchBar.placeholder = "Search entities"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    func setupContextSegmentedControl() {
        if contexts.count > 1 {
            contextSegmentedControl.removeAllSegments()
            for (index, context) in contexts.enumerated() {
                contextSegmentedControl.insertSegment(withTitle: context.name, at: index, animated: false)
            }
            contextSegmentedControl.selectedSegmentIndex = 0
            
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
        } else {
            tableView.tableHeaderView = nil
        }
    }
    
    @objc func contextChanged() {
        let index = contextSegmentedControl.selectedSegmentIndex
        guard index >= 0, index < contexts.count else { return }
        selectedContext = contexts[index].context
        loadEntities()
    }
    
    @objc func refreshData() {
        loadData()
    }
    
    func loadData() {
        contexts = CoreDataManager.shared.getAvailableContexts()
        selectedContext = CoreDataManager.shared.getDefaultContext()
        
        if contexts.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
            setupContextSegmentedControl()
            loadEntities()
        }
    }
    
    func loadEntities() {
        guard let context = selectedContext else {
            entities = []
            filteredEntities = []
            tableView.reloadData()
            return
        }
        
        entities = CoreDataManager.shared.getEntities(for: context)
        applyFilter()
    }
    
    func applyFilter() {
        let searchText = searchController.searchBar.text ?? ""
        
        if searchText.isEmpty {
            filteredEntities = entities
        } else {
            filteredEntities = entities.filter { entity in
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
            if entities.isEmpty {
                emptyStateLabel.text = "No entities found in this Core Data model."
            } else if let text = searchController.searchBar.text, !text.isEmpty {
                emptyStateLabel.text = "No results for \"\(text)\"."
            }
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }
}

// MARK: - UITableViewDataSource

extension CoreDataBrowserViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEntities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntityCell", for: indexPath) as! CoreDataEntityCell
        let entity = filteredEntities[indexPath.row]
        cell.configure(with: entity)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !filteredEntities.isEmpty else { return nil }
        return "Entities (\(filteredEntities.count))"
    }
}

// MARK: - UITableViewDelegate

extension CoreDataBrowserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let context = selectedContext else { return }
        
        let entity = filteredEntities[indexPath.row]
        let entityVC = CoreDataEntityViewController(
            entity: entity,
            context: context
        )
        navigationController?.pushViewController(entityVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UISearchResultsUpdating

extension CoreDataBrowserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}

// MARK: - Entity Cell

final class CoreDataEntityCell: UITableViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.image = UIImage(systemName: "cylinder.fill")
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
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
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(detailLabel)
        
        accessoryType = .disclosureIndicator
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            countLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            
            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 4)
        ])
    }
    
    func configure(with entity: CoreDataEntity) {
        nameLabel.text = entity.name
        countLabel.text = "\(entity.objectCount) objects"
        detailLabel.text = "\(entity.attributes.count) attributes, \(entity.relationships.count) relationships"
    }
}
