//
//  DatabaseExportViewController.swift
//  DebugSwift
//
//  Export database contents to various formats
//

import UIKit

@MainActor
final class DatabaseExportViewController: BaseController {
    private enum ExportFormat: String {
        case csv
        case json
        case sql

        var fileExtension: String {
            switch self {
            case .csv:
                return "csv"
            case .json:
                return "json"
            case .sql:
                return "sql"
            }
        }
    }

    private enum ExportError: LocalizedError {
        case noTables
        case queryFailed(table: String, message: String)
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .noTables:
                return "No tables were found to export."
            case .queryFailed(let table, let message):
                return "Failed to fetch data for table '\(table)': \(message)"
            case .encodingFailed:
                return "Unable to encode export content."
            }
        }
    }
    
    private let database: DatabaseFile
    private var tables: [DatabaseTable] = []

    private lazy var csvButton = createExportButton(title: "Export as CSV", action: #selector(exportCSV))
    private lazy var jsonButton = createExportButton(title: "Export as JSON", action: #selector(exportJSON))
    private lazy var sqlButton = createExportButton(title: "Export as SQL", action: #selector(exportSQL))
    
    init(database: DatabaseFile) {
        self.database = database
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        title = "Export Database"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel)
        )

        loadTables()
        setupExportOptions()
        updateExportAvailability()
    }
    
    private func setupExportOptions() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "Choose a format, then export all tables or a specific table."
        
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(csvButton)
        stackView.addArrangedSubview(jsonButton)
        stackView.addArrangedSubview(sqlButton)
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func loadTables() {
        switch database.type {
        case .sqlite, .coreData:
            tables = SQLiteManager.shared.getTables(from: database.path)
        case .realm:
            tables = RealmManager.shared.getTables(from: database.path)
        }
    }

    private func updateExportAvailability() {
        let isEnabled = !tables.isEmpty
        [csvButton, jsonButton, sqlButton].forEach {
            $0.isEnabled = isEnabled
            $0.alpha = isEnabled ? 1.0 : 0.5
        }
    }
    
    private func createExportButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    @objc private func exportCSV() {
        startExport(format: .csv)
    }
    
    @objc private func exportJSON() {
        startExport(format: .json)
    }
    
    @objc private func exportSQL() {
        startExport(format: .sql)
    }

    private func startExport(format: ExportFormat) {
        guard !tables.isEmpty else {
            showAlert(with: ExportError.noTables.localizedDescription)
            return
        }

        if tables.count == 1 {
            performExport(format: format, selectedTables: tables)
            return
        }

        presentTableSelection(for: format)
    }

    private func presentTableSelection(for format: ExportFormat) {
        let actionSheet = UIAlertController(
            title: "Select Tables",
            message: "Choose what to include in the export.",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(UIAlertAction(title: "All Tables", style: .default) { [weak self] _ in
            guard let self else { return }
            self.performExport(format: format, selectedTables: self.tables)
        })

        for table in tables {
            actionSheet.addAction(UIAlertAction(title: table.name, style: .default) { [weak self] _ in
                self?.performExport(format: format, selectedTables: [table])
            })
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.maxY - 1,
                width: 1,
                height: 1
            )
        }

        present(actionSheet, animated: true)
    }

    private func performExport(format: ExportFormat, selectedTables: [DatabaseTable]) {
        do {
            let data: Data
            switch format {
            case .csv:
                let csv = try makeCSVExport(for: selectedTables)
                guard let csvData = csv.data(using: .utf8) else {
                    throw ExportError.encodingFailed
                }
                data = csvData
            case .json:
                data = try makeJSONExport(for: selectedTables)
            case .sql:
                let sql = try makeSQLExport(for: selectedTables)
                guard let sqlData = sql.data(using: .utf8) else {
                    throw ExportError.encodingFailed
                }
                data = sqlData
            }

            let fileURL = try writeExportFile(
                data: data,
                format: format,
                selectedTables: selectedTables
            )
            presentShareSheet(for: fileURL)
        } catch {
            showAlert(with: error.localizedDescription, title: "Export Error")
        }
    }

    private func makeCSVExport(for selectedTables: [DatabaseTable]) throws -> String {
        var sections: [String] = []
        let includeTableHeaders = selectedTables.count > 1

        for table in selectedTables {
            let data = try fetchTableData(for: table)
            var lines: [String] = []

            if includeTableHeaders {
                lines.append("# Table: \(table.name)")
            }

            lines.append(data.columns.map(csvEscaped).joined(separator: ","))
            for row in data.rows {
                let values = data.columns.enumerated().map { index, _ in
                    let value: Any? = index < row.count ? row[index] : nil
                    return csvEscaped(valueForExport(value))
                }
                lines.append(values.joined(separator: ","))
            }

            sections.append(lines.joined(separator: "\n"))
        }

        return sections.joined(separator: "\n\n")
    }

    private func makeJSONExport(for selectedTables: [DatabaseTable]) throws -> Data {
        let isoFormatter = ISO8601DateFormatter()
        var tablePayloads: [[String: Any]] = []

        for table in selectedTables {
            let data = try fetchTableData(for: table)
            let rows: [[String: Any]] = data.rows.map { row in
                var rowObject: [String: Any] = [:]
                for (index, column) in data.columns.enumerated() {
                    let value = index < row.count ? row[index] : nil
                    rowObject[column] = jsonCompatibleValue(value)
                }
                return rowObject
            }

            tablePayloads.append([
                "name": table.name,
                "columns": data.columns,
                "rowCount": rows.count,
                "rows": rows,
            ])
        }

        let payload: [String: Any] = [
            "database": database.name,
            "databaseType": database.type.displayName,
            "exportedAt": isoFormatter.string(from: Date()),
            "tables": tablePayloads,
        ]

        return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }

    private func makeSQLExport(for selectedTables: [DatabaseTable]) throws -> String {
        let isoFormatter = ISO8601DateFormatter()
        var lines: [String] = [
            "-- DebugSwift SQL Export",
            "-- Database: \(database.name)",
            "-- Generated: \(isoFormatter.string(from: Date()))",
            "PRAGMA foreign_keys=OFF;",
            "BEGIN TRANSACTION;",
            "",
        ]

        for table in selectedTables {
            let data = try fetchTableData(for: table)
            let schemaColumns = table.columns.isEmpty
                ? data.columns.map {
                    DatabaseColumn(name: $0, type: "TEXT", isPrimaryKey: false, isNullable: true)
                }
                : table.columns

            lines.append("-- Table: \(table.name)")
            lines.append("DROP TABLE IF EXISTS \(quotedIdentifier(table.name));")

            let columnDefinitions = schemaColumns.map { column in
                var parts = [
                    quotedIdentifier(column.name),
                    column.type.isEmpty ? "TEXT" : column.type,
                ]
                if !column.isNullable {
                    parts.append("NOT NULL")
                }
                if column.isPrimaryKey {
                    parts.append("PRIMARY KEY")
                }
                return "    " + parts.joined(separator: " ")
            }

            lines.append("CREATE TABLE \(quotedIdentifier(table.name)) (")
            lines.append(columnDefinitions.joined(separator: ",\n"))
            lines.append(");")

            if !data.columns.isEmpty {
                let columnList = data.columns.map(quotedIdentifier).joined(separator: ", ")
                for row in data.rows {
                    let values = data.columns.enumerated().map { index, _ in
                        let value: Any? = index < row.count ? row[index] : nil
                        return sqlLiteral(for: value)
                    }
                    lines.append(
                        "INSERT INTO \(quotedIdentifier(table.name)) (\(columnList)) VALUES (\(values.joined(separator: ", ")));"
                    )
                }
            }

            lines.append("")
        }

        lines.append("COMMIT;")
        return lines.joined(separator: "\n")
    }

    private func fetchTableData(for table: DatabaseTable) throws -> (columns: [String], rows: [[Any?]]) {
        switch database.type {
        case .sqlite, .coreData:
            let query = "SELECT * FROM \(quotedIdentifier(table.name))"
            let result = SQLiteManager.shared.executeQuery(path: database.path, query: query)
            switch result {
            case .select(let columns, let rows):
                return (columns, rows)
            case .error(let message):
                throw ExportError.queryFailed(table: table.name, message: message)
            case .update:
                throw ExportError.queryFailed(table: table.name, message: "Unexpected non-SELECT result.")
            }
        case .realm:
            let result = RealmManager.shared.getTableData(
                from: database.path,
                table: table.name,
                limit: Int.max,
                offset: 0
            )
            return result
        }
    }

    private func writeExportFile(
        data: Data,
        format: ExportFormat,
        selectedTables: [DatabaseTable]
    ) throws -> URL {
        let fileName = makeExportFileName(format: format, selectedTables: selectedTables)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    private func makeExportFileName(format: ExportFormat, selectedTables: [DatabaseTable]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())

        let databasePart = sanitizedFileComponent(database.name)
        let tablePart: String
        if selectedTables.count == 1, let table = selectedTables.first {
            tablePart = sanitizedFileComponent(table.name)
        } else {
            tablePart = "all_tables"
        }

        return "\(databasePart)_\(tablePart)_\(timestamp).\(format.fileExtension)"
    }

    private func presentShareSheet(for fileURL: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: fileURL)
        }

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.maxY - 1,
                width: 1,
                height: 1
            )
        }

        present(activityViewController, animated: true)
    }

    private func sanitizedFileComponent(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(
            of: "[^A-Za-z0-9_-]+",
            with: "_",
            options: .regularExpression
        )
        return cleaned.isEmpty ? "export" : cleaned
    }

    private func quotedIdentifier(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private func valueForExport(_ value: Any?) -> String {
        guard let value else { return "NULL" }

        if let data = value as? Data {
            if let jsonString = data.toJSONString() {
                return jsonString
            }
            return "base64:\(data.base64EncodedString())"
        }

        return String(describing: value)
    }

    private func jsonCompatibleValue(_ value: Any?) -> Any {
        guard let value else {
            return NSNull()
        }

        if let data = value as? Data {
            if let jsonString = data.toPrettyJSONString() {
                return jsonString
            }
            return [
                "type": "blob",
                "size": data.count,
                "base64": data.base64EncodedString(),
            ]
        }

        if value is String || value is Int || value is Int64 || value is Double || value is Float || value is Bool {
            return value
        }

        return String(describing: value)
    }

    private func sqlLiteral(for value: Any?) -> String {
        guard let value else { return "NULL" }

        if let intValue = value as? Int {
            return "\(intValue)"
        }

        if let int64Value = value as? Int64 {
            return "\(int64Value)"
        }

        if let doubleValue = value as? Double {
            return "\(doubleValue)"
        }

        if let floatValue = value as? Float {
            return "\(floatValue)"
        }

        if let boolValue = value as? Bool {
            return boolValue ? "1" : "0"
        }

        if let data = value as? Data {
            let hex = data.map { String(format: "%02X", $0) }.joined()
            return "X'\(hex)'"
        }

        let stringValue = String(describing: value).replacingOccurrences(of: "'", with: "''")
        return "'\(stringValue)'"
    }
}
