//
//  DatabaseTableViewController.swift
//  DebugSwift
//
//  View controller for displaying database table contents
//

import UIKit

@MainActor
final class DatabaseTableViewController: BaseController {
    
    // MARK: - Properties
    
    private let database: DatabaseFile
    private let table: DatabaseTable
    private var columns: [String] = []
    private var rows: [[Any?]] = []
    private var filteredRows: [[Any?]] = []
    private var currentSearchText = ""
    private var currentPage = 0
    private let pageSize = 100
    private var sortColumn: String?
    private var sortAscending = true
    
    private lazy var horizontalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(DatabaseDataCell.self, forCellReuseIdentifier: "DataCell")
        table.allowsSelection = true
        table.separatorStyle = .singleLine
        table.showsVerticalScrollIndicator = true
        return table
    }()
    
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search in table"
        return search
    }()
    
    private lazy var editButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Editar",
            style: .plain,
            target: self,
            action: #selector(toggleEditMode)
        )
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewRow)
        )
    }()
    
    private lazy var headerView: DatabaseTableHeaderView = {
        let header = DatabaseTableHeaderView()
        header.delegate = self
        return header
    }()
    
    // MARK: - Initialization
    
    init(database: DatabaseFile, table: DatabaseTable) {
        self.database = database
        self.table = table
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadTableData()
        setupLongPressGesture()
    }
    
    private func setupLongPressGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              database.type == .sqlite else { return }
        
        let point = gesture.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            showRowActionSheet(for: indexPath)
        }
    }
}

// MARK: - Setup

private extension DatabaseTableViewController {
    func setup() {
        setupViews()
        setupNavigation()
    }
    
    func setupViews() {
        view.addSubview(horizontalScrollView)
        horizontalScrollView.addSubview(contentView)
        contentView.addSubview(tableView)
        
        // Calculate minimum width based on column count
        let minWidth = max(view.bounds.width, CGFloat(columns.count * 120))
        
        NSLayoutConstraint.activate([
            // Horizontal scroll view constraints
            horizontalScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            horizontalScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            horizontalScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: horizontalScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: horizontalScrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: horizontalScrollView.heightAnchor),
            contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth),
            
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func setupNavigation() {
        title = table.name
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        if database.type == .sqlite {
            navigationItem.rightBarButtonItems = [editButton, addButton]
        }
    }
    
    func loadTableData() {
        let result = SQLiteManager.shared.getTableData(
            from: database.path,
            table: table.name,
            limit: pageSize,
            offset: currentPage * pageSize,
            orderBy: sortColumn,
            ascending: sortAscending
        )
        
        columns = result.columns
        rows = result.rows
        applySearchFilter()
        
        // Update content width based on column count
        let columnWidth: CGFloat = 150
        let totalWidth = max(view.bounds.width, CGFloat(columns.count) * columnWidth + 32)
        
        // Update content view width constraint
        contentView.constraints.first(where: { $0.firstAttribute == .width })?.isActive = false
        contentView.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true
        
        headerView.configure(with: columns, columnWidth: columnWidth)
        headerView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: 44)
        tableView.tableHeaderView = headerView
        
        tableView.reloadData()
        
        // Ensure horizontal scroll view updates its content size
        horizontalScrollView.layoutIfNeeded()
    }
    
    @objc func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        editButton.title = tableView.isEditing ? "Salvar" : "Editar"
        
        // If exiting edit mode, reload data to refresh any changes
        if !tableView.isEditing {
            loadTableData()
        }
    }
    
    @objc func addNewRow() {
        let addVC = DatabaseRowEditViewController(
            database: database,
            table: table,
            columns: columns,
            row: nil,
            isNewRow: true
        )
        addVC.delegate = self
        let navController = UINavigationController(rootViewController: addVC)
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension DatabaseTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath) as! DatabaseDataCell
        let row = filteredRows[indexPath.row]
        let columnWidth: CGFloat = 150
        cell.configure(with: row, columns: columns, columnWidth: columnWidth)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return database.type == .sqlite
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            showDeleteConfirmation(for: indexPath)
        }
    }
}

// MARK: - UITableViewDelegate

extension DatabaseTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Only open edit view if in edit mode or if database is SQLite
        if tableView.isEditing && database.type == .sqlite {
            let row = filteredRows[indexPath.row]
            let editVC = DatabaseRowEditViewController(
                database: database,
                table: table,
                columns: columns,
                row: row,
                isNewRow: false
            )
            editVC.delegate = self
            let navController = UINavigationController(rootViewController: editVC)
            present(navController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UISearchResultsUpdating

extension DatabaseTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        currentSearchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        applySearchFilter()
        tableView.reloadData()
    }
}

// MARK: - DatabaseTableHeaderViewDelegate

extension DatabaseTableViewController: DatabaseTableHeaderViewDelegate {
    func headerView(_ headerView: DatabaseTableHeaderView, didTapColumn column: String) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
        
        currentPage = 0
        loadTableData()
    }
}

// MARK: - DatabaseRowEditDelegate

extension DatabaseTableViewController: DatabaseRowEditDelegate {
    func didSaveRow() {
        loadTableData()
    }
}

// MARK: - Helper Methods

private extension DatabaseTableViewController {
    func applySearchFilter() {
        guard !currentSearchText.isEmpty else {
            filteredRows = rows
            return
        }

        let query = currentSearchText.lowercased()
        filteredRows = rows.filter { row in
            row.contains { value in
                valueMatchesQuery(value, query: query)
            }
        }
    }

    func valueMatchesQuery(_ value: Any?, query: String) -> Bool {
        guard let value else {
            return "null".contains(query)
        }

        if let data = value as? Data {
            if let jsonString = data.toJSONString() {
                return jsonString.lowercased().contains(query)
            }
            return "<blob \(data.count) bytes>".contains(query)
        }

        return String(describing: value).lowercased().contains(query)
    }

    func showRowActionSheet(for indexPath: IndexPath) {
        let actionSheet = UIAlertController(
            title: "Row Actions",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Edit action
        actionSheet.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.editRow(at: indexPath)
        })
        
        // Duplicate action
        actionSheet.addAction(UIAlertAction(title: "Duplicate", style: .default) { [weak self] _ in
            self?.duplicateRow(at: indexPath)
        })
        
        // Delete action
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation(for: indexPath)
        })
        
        // Cancel action
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = tableView
            let cellRect = tableView.rectForRow(at: indexPath)
            popover.sourceRect = cellRect
        }
        
        present(actionSheet, animated: true)
    }
    
    func editRow(at indexPath: IndexPath) {
        guard indexPath.row < filteredRows.count else { return }
        
        let row = filteredRows[indexPath.row]
        let editVC = DatabaseRowEditViewController(
            database: database,
            table: table,
            columns: columns,
            row: row,
            isNewRow: false
        )
        editVC.delegate = self
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
    
    func duplicateRow(at indexPath: IndexPath) {
        guard indexPath.row < filteredRows.count else { return }
        
        var row = filteredRows[indexPath.row]
        
        // Find primary key and set it to nil to create a new row
        if let primaryKeyColumn = table.columns.first(where: { $0.isPrimaryKey }),
           let primaryKeyIndex = columns.firstIndex(of: primaryKeyColumn.name) {
            row[primaryKeyIndex] = nil
        }
        
        let editVC = DatabaseRowEditViewController(
            database: database,
            table: table,
            columns: columns,
            row: row,
            isNewRow: true
        )
        editVC.delegate = self
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
    
    func showDeleteConfirmation(for indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Row",
            message: "Are you sure you want to delete this row?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteRow(at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    func deleteRow(at indexPath: IndexPath) {
        guard let primaryKeyColumn = table.columns.first(where: { $0.isPrimaryKey })?.name,
              let primaryKeyIndex = columns.firstIndex(of: primaryKeyColumn),
              indexPath.row < filteredRows.count else {
            showAlert(with: "Cannot delete row without primary key")
            return
        }
        
        let row = filteredRows[indexPath.row]
        guard let primaryKeyValue = row[primaryKeyIndex] else {
            showAlert(with: "Primary key value is missing")
            return
        }
        
        let whereClause = "\(primaryKeyColumn) = ?"
        let result = SQLiteManager.shared.executeDelete(
            path: database.path,
            table: table.name,
            whereClause: whereClause,
            values: [primaryKeyValue]
        )
        
        switch result {
        case .update(let affectedRows):
            if affectedRows > 0 {
                loadTableData()
            } else {
                showAlert(with: "No rows were deleted")
            }
        case .error(let message):
            showAlert(with: "Error deleting row: \(message)")
        default:
            break
        }
    }
}

// MARK: - Database Data Cell

final class DatabaseDataCell: UITableViewCell {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -16)
        ])
    }
    
    func configure(with row: [Any?], columns: [String], columnWidth: CGFloat = 150) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (_, value) in row.enumerated() {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14)
            label.textAlignment = .left
            label.numberOfLines = 2
            label.lineBreakMode = .byTruncatingTail
            label.translatesAutoresizingMaskIntoConstraints = false
            
            if let value = value {
                if let data = value as? Data {
                    // Try to convert to JSON string
                    if let jsonString = data.toJSONString() {
                        label.text = jsonString
                        label.textColor = .systemBlue
                    } else {
                        label.text = "<BLOB \(data.count) bytes>"
                        label.textColor = .systemGray
                    }
                } else {
                    label.text = "\(value)"
                    label.textColor = .label
                }
            } else {
                label.text = "NULL"
                label.textColor = .systemGray
            }
            
            label.widthAnchor.constraint(equalToConstant: columnWidth - 8).isActive = true
            stackView.addArrangedSubview(label)
        }
        
        // Update scroll view content size
        scrollView.layoutIfNeeded()
    }
}

// MARK: - Database Table Header View

@MainActor
protocol DatabaseTableHeaderViewDelegate: AnyObject {
    func headerView(_ headerView: DatabaseTableHeaderView, didTapColumn column: String)
}

final class DatabaseTableHeaderView: UIView {
    weak var delegate: DatabaseTableHeaderViewDelegate?
    private var columns: [String] = []
    private var columnWidth: CGFloat = 150
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 8
        stack.backgroundColor = .systemGray6
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemGray6
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    func configure(with columns: [String], columnWidth: CGFloat = 150) {
        self.columns = columns
        self.columnWidth = columnWidth
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, column) in columns.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(column, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.tag = index
            button.addTarget(self, action: #selector(columnTapped(_:)), for: .touchUpInside)
            button.contentHorizontalAlignment = .left
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: columnWidth - 8).isActive = true
            stackView.addArrangedSubview(button)
        }
        
        // Update scroll view content size
        scrollView.layoutIfNeeded()
    }
    
    @objc private func columnTapped(_ sender: UIButton) {
        let column = columns[sender.tag]
        delegate?.headerView(self, didTapColumn: column)
    }
}

// MARK: - Protocols

@MainActor
protocol DatabaseRowEditDelegate: AnyObject {
    func didSaveRow()
}
