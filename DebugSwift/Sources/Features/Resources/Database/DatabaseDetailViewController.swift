//
//  DatabaseDetailViewController.swift
//  DebugSwift
//
//  Detail view for browsing database tables and content
//

import UIKit
import SQLite3

@MainActor
final class DatabaseDetailViewController: BaseController {
    
    // MARK: - Properties
    
    private let database: DatabaseFile
    private var tables: [DatabaseTable] = []
    private var searchController: UISearchController!
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TableCell")
        return table
    }()
    
    private lazy var queryButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "text.cursor"),
            style: .plain,
            target: self,
            action: #selector(showQueryEditor)
        )
    }()
    
    private lazy var exportButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportDatabase)
        )
    }()
    
    // MARK: - Initialization
    
    init(database: DatabaseFile) {
        self.database = database
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadTables()
    }
}

// MARK: - Setup

private extension DatabaseDetailViewController {
    func setup() {
        setupViews()
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
    
    func setupNavigation() {
        title = database.name
        
        if database.type == .sqlite {
            navigationItem.rightBarButtonItems = [exportButton, queryButton]
        } else {
            navigationItem.rightBarButtonItem = exportButton
        }
    }
    
    func loadTables() {
        switch database.type {
        case .sqlite, .coreData:
            tables = SQLiteManager.shared.getTables(from: database.path)
        case .realm:
            tables = RealmManager.shared.getTables(from: database.path)
        }
        tableView.reloadData()
    }
    
    @objc func showQueryEditor() {
        let queryVC = SQLQueryViewController(database: database)
        let navController = UINavigationController(rootViewController: queryVC)
        present(navController, animated: true)
    }
    
    @objc func exportDatabase() {
        let exportVC = DatabaseExportViewController(database: database)
        let navController = UINavigationController(rootViewController: exportVC)
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension DatabaseDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tables.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)
        let table = tables[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = table.name
        content.secondaryText = "\(table.rowCount) rows"
        content.image = UIImage(systemName: "tablecells")
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Tables (\(tables.count))"
    }
}

// MARK: - UITableViewDelegate

extension DatabaseDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let table = tables[indexPath.row]
        let tableContentVC = DatabaseTableViewController(
            database: database,
            table: table
        )
        navigationController?.pushViewController(tableContentVC, animated: true)
    }
}

// MARK: - Database Table Model

struct DatabaseTable {
    let name: String
    let rowCount: Int
    let columns: [DatabaseColumn]
}

struct DatabaseColumn {
    let name: String
    let type: String
    let isPrimaryKey: Bool
    let isNullable: Bool
} 