//
//  SQLQueryViewController.swift
//  DebugSwift
//
//  SQL query editor for custom database queries
//

import UIKit

@MainActor
final class SQLQueryViewController: BaseController {
    
    // MARK: - Properties
    
    private let database: DatabaseFile
    private var queryHistory: [String] = []
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.text = "SELECT * FROM "
        return textView
    }()
    
    private lazy var executeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Execute Query", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(executeQuery), for: .touchUpInside)
        return button
    }()
    
    private lazy var resultTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
        table.isHidden = true
        return table
    }()
    
    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private var resultColumns: [String] = []
    private var resultRows: [[Any?]] = []
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
}

// MARK: - Setup

private extension SQLQueryViewController {
    func setup() {
        setupViews()
        setupNavigation()
        setupKeyboardHandling()
    }
    
    func setupViews() {
        view.addSubview(textView)
        view.addSubview(executeButton)
        view.addSubview(resultTableView)
        view.addSubview(resultLabel)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 150),
            
            executeButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            executeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            executeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            executeButton.heightAnchor.constraint(equalToConstant: 44),
            
            resultTableView.topAnchor.constraint(equalTo: executeButton.bottomAnchor, constant: 16),
            resultTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            resultLabel.topAnchor.constraint(equalTo: executeButton.bottomAnchor, constant: 16),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resultLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        resultTableView.dataSource = self
        resultTableView.delegate = self
    }
    
    func setupNavigation() {
        title = "SQL Query Editor"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismiss(_:))
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "clock.arrow.circlepath"),
            style: .plain,
            target: self,
            action: #selector(showHistory)
        )
    }
    
    func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc func executeQuery() {
        guard let query = textView.text, !query.isEmpty else { return }
        
        textView.resignFirstResponder()
        
        // Add to history
        if !queryHistory.contains(query) {
            queryHistory.insert(query, at: 0)
            if queryHistory.count > 20 {
                queryHistory.removeLast()
            }
        }
        
        // Execute query
        let result = SQLiteManager.shared.executeQuery(path: database.path, query: query)
        
        switch result {
        case .select(let columns, let rows):
            showSelectResults(columns: columns, rows: rows)
        case .update(let affectedRows):
            showUpdateResult(affectedRows: affectedRows)
        case .error(let message):
            showError(message: message)
        }
    }
    
    @objc func showHistory() {
        let historyVC = QueryHistoryViewController(history: queryHistory) { [weak self] selectedQuery in
            self?.textView.text = selectedQuery
            self?.dismiss(animated: true)
        }
        let nav = UINavigationController(rootViewController: historyVC)
        present(nav, animated: true)
    }
    
    func showSelectResults(columns: [String], rows: [[Any?]]) {
        resultColumns = columns
        resultRows = rows
        
        resultTableView.isHidden = false
        resultLabel.isHidden = true
        resultTableView.reloadData()
        
        if rows.isEmpty {
            resultLabel.text = "No results found"
            resultLabel.isHidden = false
            resultTableView.isHidden = true
        }
    }
    
    func showUpdateResult(affectedRows: Int) {
        resultTableView.isHidden = true
        resultLabel.isHidden = false
        resultLabel.textColor = .systemGreen
        resultLabel.text = "Query executed successfully.\n\(affectedRows) row(s) affected."
    }
    
    func showError(message: String) {
        resultTableView.isHidden = true
        resultLabel.isHidden = false
        resultLabel.textColor = .systemRed
        resultLabel.text = "Error: \(message)"
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        // Handle keyboard appearance
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // Handle keyboard disappearance
    }
}

// MARK: - UITableViewDataSource

extension SQLQueryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultRows.count + 1 // +1 for header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        
        if indexPath.row == 0 {
            // Header row
            var content = cell.defaultContentConfiguration()
            content.text = resultColumns.joined(separator: " | ")
            content.textProperties.font = .systemFont(ofSize: 14, weight: .semibold)
            cell.contentConfiguration = content
            cell.backgroundColor = .systemGray6
        } else {
            // Data row
            let row = resultRows[indexPath.row - 1]
            let values = row.map { value -> String in
                if let value = value {
                    if let data = value as? Data {
                        // Try to convert to JSON string
                        if let jsonString = data.toJSONString() {
                            return jsonString
                        } else {
                            return "<BLOB \(data.count)b>"
                        }
                    }
                    return "\(value)"
                }
                return "NULL"
            }
            
            var content = cell.defaultContentConfiguration()
            content.text = values.joined(separator: " | ")
            content.textProperties.font = .systemFont(ofSize: 14)
            cell.contentConfiguration = content
            cell.backgroundColor = .systemBackground
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SQLQueryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Query History View Controller

@MainActor
final class QueryHistoryViewController: UITableViewController {
    private let history: [String]
    private let onSelect: (String) -> Void
    
    init(history: [String], onSelect: @escaping (String) -> Void) {
        self.history = history
        self.onSelect = onSelect
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Query History"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismiss(_:))
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
    }
    
    @objc func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = history[indexPath.row]
        content.textProperties.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        content.textProperties.numberOfLines = 2
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect(history[indexPath.row])
    }
}

