//
//  DatabaseBrowserViewController.swift
//  DebugSwift
//
//  Database browser for SQLite and Realm databases
//

import UIKit

@MainActor
final class DatabaseBrowserViewController: BaseController {
    
    // MARK: - Properties
    
    private let allowedTypes: Set<DatabaseType>?
    private let viewModel: DatabaseBrowserViewModel
    private var searchController: UISearchController!
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(DatabaseFileCell.self, forCellReuseIdentifier: "DatabaseFileCell")
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

    init(allowedTypes: Set<DatabaseType>? = nil) {
        self.allowedTypes = allowedTypes
        self.viewModel = DatabaseBrowserViewModel(allowedTypes: allowedTypes)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.loadDatabaseFiles()
        reloadDataUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ImpactFeedback.generate()
    }
}

// MARK: - Setup

private extension DatabaseBrowserViewController {
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
        if allowedTypes == [.coreData] {
            title = "Core Data Browser"
        } else {
            title = "Database Browser"
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshDatabases)
        )
    }
    
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search databases"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    @objc func refreshDatabases() {
        viewModel.loadDatabaseFiles()
        reloadDataUI()
    }

    func reloadDataUI() {
        tableView.reloadData()
        updateEmptyState()
    }

    func updateEmptyState() {
        let isEmpty = viewModel.filteredDatabases.isEmpty
        guard isEmpty else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return
        }

        if viewModel.databases.isEmpty {
            if allowedTypes == [.coreData] {
                emptyStateLabel.text = "No Core Data stores were found."
            } else {
                emptyStateLabel.text = "No databases were found."
            }
        } else if let text = searchController.searchBar.text,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emptyStateLabel.text = "No results for \"\(text)\"."
        } else {
            emptyStateLabel.text = "No databases available."
        }

        tableView.backgroundView = emptyStateLabel
        tableView.separatorStyle = .none
    }
}

// MARK: - UITableViewDataSource

extension DatabaseBrowserViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredDatabases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DatabaseFileCell", for: indexPath) as! DatabaseFileCell
        let database = viewModel.filteredDatabases[indexPath.row]
        cell.configure(with: database)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Available Databases"
    }
}

// MARK: - UITableViewDelegate

extension DatabaseBrowserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let database = viewModel.filteredDatabases[indexPath.row]
        let detailVC = DatabaseDetailViewController(database: database)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UISearchResultsUpdating

extension DatabaseBrowserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.filterDatabases(with: searchController.searchBar.text)
        reloadDataUI()
    }
}

// MARK: - Database File Cell

final class DatabaseFileCell: UITableViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let sizeLabel: UILabel = {
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
        contentView.addSubview(typeLabel)
        contentView.addSubview(sizeLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            typeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            typeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4)
        ])
    }
    
    func configure(with database: DatabaseFile) {
        nameLabel.text = database.name
        typeLabel.text = database.type.displayName
        sizeLabel.text = database.formattedSize
        iconImageView.image = database.type.icon
    }
}
