//
//  DatabaseRowEditViewController.swift
//  DebugSwift
//
//  Edit individual database rows
//

import UIKit

@MainActor
final class DatabaseRowEditViewController: BaseController {
    
    weak var delegate: DatabaseRowEditDelegate?
    
    private let database: DatabaseFile
    private let table: DatabaseTable
    private let columns: [String]
    private let originalRow: [Any?]?
    private let isNewRow: Bool
    
    private var textFields: [UITextField] = []
    private var textViews: [UITextView] = [] // For JSON/Data fields
    private var values: [Any?] = []
    private var dataFieldIndices: Set<Int> = [] // Track which fields are Data type
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fill
        return stack
    }()
    
    init(
        database: DatabaseFile,
        table: DatabaseTable,
        columns: [String],
        row: [Any?]?,
        isNewRow: Bool
    ) {
        self.database = database
        self.table = table
        self.columns = columns
        self.originalRow = row
        self.isNewRow = isNewRow
        self.values = row ?? Array(repeating: nil, count: columns.count)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupFields()
    }
    
    private func setup() {
        title = isNewRow ? "Add Row" : "Edit Row"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(save)
        )
        
        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        setupKeyboardDismissGesture()
    }
    
    private func setupFields() {
        textFields.removeAll()
        textViews.removeAll()
        dataFieldIndices.removeAll()
        
        for (index, column) in columns.enumerated() {
            let columnInfo = table.columns.first(where: { $0.name == column })
            
            // Create container for label and text field
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            
            // Label
            let label = UILabel()
            label.text = column
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            
            // Add type and constraint info
            if let columnInfo = columnInfo {
                var typeInfo = columnInfo.type
                if columnInfo.isPrimaryKey {
                    typeInfo += " (PRIMARY KEY)"
                }
                if !columnInfo.isNullable {
                    typeInfo += " NOT NULL"
                }
                label.text = "\(column) - \(typeInfo)"
            }
            
            // Check if this is a BLOB/Data field
            let isDataField = index < values.count && values[index] is Data
            
            if isDataField {
                // Use TextView for JSON data
                let textView = UITextView()
                textView.translatesAutoresizingMaskIntoConstraints = false
                textView.layer.borderColor = UIColor.separator.cgColor
                textView.layer.borderWidth = 0.5
                textView.layer.cornerRadius = 6
                textView.backgroundColor = .secondarySystemBackground
                textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
                textView.tag = index
                
                // Set initial value
                if let data = values[index] as? Data {
                    if let jsonString = data.toPrettyJSONString() {
                        textView.text = jsonString
                        textView.textColor = .label
                    } else {
                        textView.text = "<Binary data - \(data.count) bytes>"
                        textView.textColor = .systemGray
                        textView.isEditable = false
                    }
                } else {
                    textView.text = ""
                }
                
                textViews.append(textView)
                dataFieldIndices.insert(index)
                
                // Add to container
                container.addSubview(label)
                container.addSubview(textView)
                
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: container.topAnchor),
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    
                    textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
                    textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    textView.heightAnchor.constraint(equalToConstant: 120)
                ])
            } else {
                // Use TextField for regular data
                let textField = UITextField()
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.borderStyle = .roundedRect
                textField.backgroundColor = .secondarySystemBackground
                textField.tag = index
                
                // Set placeholder
                if columnInfo?.isNullable == true {
                    textField.placeholder = "NULL"
                }
                
                // Set keyboard type based on column type
                if let type = columnInfo?.type.uppercased() {
                    if type.contains("INT") || type.contains("REAL") || type.contains("NUMERIC") {
                        textField.keyboardType = .numbersAndPunctuation
                    }
                }
                
                // Set initial value
                if index < values.count, let value = values[index] {
                    textField.text = "\(value)"
                }
                
                // Disable primary key editing on existing rows
                if !isNewRow && columnInfo?.isPrimaryKey == true {
                    textField.isEnabled = false
                    textField.textColor = .systemGray
                }
                
                textFields.append(textField)
                
                // Add to container
                container.addSubview(label)
                container.addSubview(textField)
                
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: container.topAnchor),
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    
                    textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
                    textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    textField.heightAnchor.constraint(equalToConstant: 44)
                ])
            }
            
            stackView.addArrangedSubview(container)
        }
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    @objc private func save() {
        // Collect values from text fields and text views
        var newValues: [Any?] = []
        var textFieldIndex = 0
        var textViewIndex = 0
        
        for (index, _) in columns.enumerated() {
            if dataFieldIndices.contains(index) {
                // This is a Data field - get from text view
                let textView = textViews[textViewIndex]
                let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                textViewIndex += 1
                
                if text.isEmpty || text.uppercased() == "NULL" {
                    newValues.append(nil)
                } else if !textView.isEditable {
                    // Binary data that couldn't be edited - keep original
                    newValues.append(values[index])
                } else {
                    // Try to convert JSON string to Data
                    if let data = text.data(using: .utf8) {
                        // Validate JSON
                        if (try? JSONSerialization.jsonObject(with: data, options: [])) != nil {
                            newValues.append(data)
                        } else {
                            // Not valid JSON, save as plain text data
                            newValues.append(data)
                        }
                    } else {
                        newValues.append(nil)
                    }
                }
            } else {
                // Regular field - get from text field
                let textField = textFields[textFieldIndex]
                let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                textFieldIndex += 1
                
                if text?.isEmpty == true || text?.uppercased() == "NULL" {
                    newValues.append(nil)
                } else {
                    // Try to convert based on column type
                    if let columnInfo = table.columns.first(where: { $0.name == columns[index] }) {
                        let type = columnInfo.type.uppercased()
                        
                        if type.contains("INT") {
                            newValues.append(Int(text ?? "") ?? text)
                        } else if type.contains("REAL") || type.contains("NUMERIC") {
                            newValues.append(Double(text ?? "") ?? text)
                        } else if type.contains("BLOB") || type.contains("DATA") {
                            // Convert string to data
                            newValues.append(text?.data(using: .utf8))
                        } else {
                            newValues.append(text)
                        }
                    } else {
                        newValues.append(text)
                    }
                }
            }
        }
        
        // Build and execute SQL
        if isNewRow {
            executeInsert(values: newValues)
        } else {
            executeUpdate(values: newValues)
        }
    }
    
    private func executeInsert(values: [Any?]) {
        let placeholders = Array(repeating: "?", count: columns.count).joined(separator: ", ")
        let columnNames = columns.map(quotedIdentifier).joined(separator: ", ")
        let query = "INSERT INTO \(quotedIdentifier(table.name)) (\(columnNames)) VALUES (\(placeholders))"
        
        let result = SQLiteManager.shared.executeInsert(
            path: database.path,
            query: query,
            values: values
        )
        
        handleResult(result)
    }
    
    private func executeUpdate(values: [Any?]) {
        guard let primaryKeyColumn = table.columns.first(where: { $0.isPrimaryKey })?.name,
              let primaryKeyIndex = columns.firstIndex(of: primaryKeyColumn),
              let primaryKeyValue = originalRow?[primaryKeyIndex] else {
            showAlert(with: "Cannot update row without primary key")
            return
        }
        
        var setClause: [String] = []
        var updateValues: [Any?] = []
        
        for (index, column) in columns.enumerated() {
            // Skip primary key in SET clause
            if column != primaryKeyColumn {
                setClause.append("\(quotedIdentifier(column)) = ?")
                updateValues.append(values[index])
            }
        }
        
        let query = "UPDATE \(quotedIdentifier(table.name)) SET \(setClause.joined(separator: ", ")) WHERE \(quotedIdentifier(primaryKeyColumn)) = ?"
        updateValues.append(primaryKeyValue)
        
        let result = SQLiteManager.shared.executeUpdate(
            path: database.path,
            query: query,
            values: updateValues
        )
        
        handleResult(result)
    }
    
    private func handleResult(_ result: QueryResult) {
        switch result {
        case .update(let affectedRows):
            if affectedRows > 0 {
                delegate?.didSaveRow()
                dismiss(animated: true)
            } else {
                showAlert(with: "No rows were affected")
            }
        case .error(let message):
            showAlert(with: "Error: \(message)")
        default:
            break
        }
    }

    private func quotedIdentifier(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
