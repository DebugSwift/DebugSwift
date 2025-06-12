//
//  HTTPFilterController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class HTTPFilterController: BaseTableController {
    
    // MARK: - Properties
    
    private var filter: HTTPRequestFilter
    private let onFilterChanged: (HTTPRequestFilter) -> Void
    
    private enum Section: Int, CaseIterable {
        case methods
        case statusCodes
        case contentTypes
        case responseTime
        case size
        case errorSuccess
        case hosts
        case timeRange
        case actions
        
        var title: String {
            switch self {
            case .methods: return "HTTP METHODS"
            case .statusCodes: return "STATUS CODES"
            case .contentTypes: return "CONTENT TYPES"
            case .responseTime: return "RESPONSE TIME"
            case .size: return "RESPONSE SIZE"
            case .errorSuccess: return "SUCCESS/ERROR"
            case .hosts: return "HOSTS"
            case .timeRange: return "TIME RANGE"
            case .actions: return "ACTIONS"
            }
        }
    }
    
    private let httpMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"]
    private let contentTypeOptions = ["json", "xml", "html", "image", "text", "video", "audio", "pdf"]
    
    // MARK: - Initialization
    
    init(currentFilter: HTTPRequestFilter, onFilterChanged: @escaping (HTTPRequestFilter) -> Void) {
        self.filter = currentFilter
        self.onFilterChanged = onFilterChanged
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Filter Requests"
        view.backgroundColor = .black
        
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        
        setupNavigationBar()
        registerCells()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(applyTapped)
            ),
            UIBarButtonItem(
                title: "Clear",
                style: .plain,
                target: self,
                action: #selector(clearAllTapped)
            )
        ]
    }
    
    private func registerCells() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func applyTapped() {
        onFilterChanged(filter)
        dismiss(animated: true)
    }
    
    @objc private func clearAllTapped() {
        filter = HTTPRequestFilter()
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .methods:
            return httpMethods.count
        case .statusCodes:
            return StatusCodeRange.allRanges.count
        case .contentTypes:
            return contentTypeOptions.count
        case .responseTime:
            return 2 // Min and Max
        case .size:
            return 2 // Min and Max
        case .errorSuccess:
            return 2 // Show errors only, Show success only
        case .hosts:
            return 1 // Text field for host filtering
        case .timeRange:
            return 3 // Last hour, Last day, Custom
        case .actions:
            return 1 // Clear all button
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .methods:
            return methodCell(for: indexPath)
        case .statusCodes:
            return statusCodeCell(for: indexPath)
        case .contentTypes:
            return contentTypeCell(for: indexPath)
        case .responseTime:
            return responseTimeCell(for: indexPath)
        case .size:
            return sizeCell(for: indexPath)
        case .errorSuccess:
            return errorSuccessCell(for: indexPath)
        case .hosts:
            return hostCell(for: indexPath)
        case .timeRange:
            return timeRangeCell(for: indexPath)
        case .actions:
            return actionCell(for: indexPath)
        }
    }
    
    // MARK: - Cell Creation Methods
    
    private func methodCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        let method = httpMethods[indexPath.row]
        
        cell.textLabel?.text = method
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .black
        cell.accessoryType = filter.methods.contains(method) ? .checkmark : .none
        cell.selectionStyle = .default
        
        return cell
    }
    
    private func statusCodeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        let range = StatusCodeRange.allRanges[indexPath.row]
        
        cell.textLabel?.text = range.name
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .black
        cell.accessoryType = filter.statusCodeRanges.contains(where: { $0.min == range.min && $0.max == range.max }) ? .checkmark : .none
        cell.selectionStyle = .default
        
        return cell
    }
    
    private func contentTypeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        let contentType = contentTypeOptions[indexPath.row]
        
        cell.textLabel?.text = contentType.uppercased()
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .black
        cell.accessoryType = filter.contentTypes.contains(contentType) ? .checkmark : .none
        cell.selectionStyle = .default
        
        return cell
    }
    
    private func responseTimeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
        
        if indexPath.row == 0 {
            cell.configure(
                title: "Min Response Time (s)",
                placeholder: "0.0",
                keyboardType: .decimalPad,
                currentValue: filter.minResponseTime?.description
            ) { [weak self] value in
                self?.filter.minResponseTime = Double(value)
            }
        } else {
            cell.configure(
                title: "Max Response Time (s)",
                placeholder: "10.0",
                keyboardType: .decimalPad,
                currentValue: filter.maxResponseTime?.description
            ) { [weak self] value in
                self?.filter.maxResponseTime = Double(value)
            }
        }
        
        return cell
    }
    
    private func sizeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
        
        if indexPath.row == 0 {
            cell.configure(
                title: "Min Size (bytes)",
                placeholder: "0",
                keyboardType: .numberPad,
                currentValue: filter.minSize?.description
            ) { [weak self] value in
                self?.filter.minSize = Int(value)
            }
        } else {
            cell.configure(
                title: "Max Size (bytes)",
                placeholder: "1000000",
                keyboardType: .numberPad,
                currentValue: filter.maxSize?.description
            ) { [weak self] value in
                self?.filter.maxSize = Int(value)
            }
        }
        
        return cell
    }
    
    private func errorSuccessCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
        
        if indexPath.row == 0 {
            cell.configure(
                title: "Show Only Errors",
                isOn: filter.showOnlyErrors
            ) { [weak self] isOn in
                self?.filter.showOnlyErrors = isOn
                if isOn {
                    self?.filter.showOnlySuccessful = false
                    self?.tableView.reloadRows(at: [IndexPath(row: 1, section: indexPath.section)], with: .none)
                }
            }
        } else {
            cell.configure(
                title: "Show Only Successful",
                isOn: filter.showOnlySuccessful
            ) { [weak self] isOn in
                self?.filter.showOnlySuccessful = isOn
                if isOn {
                    self?.filter.showOnlyErrors = false
                    self?.tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .none)
                }
            }
        }
        
        return cell
    }
    
    private func hostCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
        
        cell.configure(
            title: "Host Filter",
            placeholder: "api.example.com",
            keyboardType: .default,
            currentValue: filter.hostFilters.first
        ) { [weak self] value in
            self?.filter.hostFilters = value.isEmpty ? [] : [value]
        }
        
        return cell
    }
    
    private func timeRangeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.selectionStyle = .default
        
        let isSelected: Bool
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Last Hour"
            isSelected = filter.timeRange?.displayName == "Last Hour"
        case 1:
            cell.textLabel?.text = "Last Day"
            isSelected = filter.timeRange?.displayName == "Last Day"
        case 2:
            cell.textLabel?.text = "Custom Range"
            isSelected = filter.timeRange != nil && filter.timeRange?.displayName.contains("Last") == false
        default:
            cell.textLabel?.text = ""
            isSelected = false
        }
        
        cell.accessoryType = isSelected ? .checkmark : .none
        
        return cell
    }
    
    private func actionCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        
        cell.textLabel?.text = "Clear All Filters"
        cell.textLabel?.textColor = .systemRed
        cell.textLabel?.textAlignment = .center
        cell.backgroundColor = .black
        cell.selectionStyle = .default
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .methods:
            let method = httpMethods[indexPath.row]
            if filter.methods.contains(method) {
                filter.methods.remove(method)
            } else {
                filter.methods.insert(method)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            
        case .statusCodes:
            let range = StatusCodeRange.allRanges[indexPath.row]
            if let existingIndex = filter.statusCodeRanges.firstIndex(where: { $0.min == range.min && $0.max == range.max }) {
                filter.statusCodeRanges.remove(at: existingIndex)
            } else {
                filter.statusCodeRanges.append(range)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            
        case .contentTypes:
            let contentType = contentTypeOptions[indexPath.row]
            if filter.contentTypes.contains(contentType) {
                filter.contentTypes.remove(contentType)
            } else {
                filter.contentTypes.insert(contentType)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            
        case .timeRange:
            switch indexPath.row {
            case 0:
                filter.timeRange = .lastHour
            case 1:
                filter.timeRange = .lastDay
            case 2:
                // Show date picker for custom range
                showCustomDateRangePicker()
            default:
                break
            }
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
            
        case .actions:
            clearAllTapped()
            
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func showCustomDateRangePicker() {
        // For now, just set to last day as placeholder
        // In a real implementation, you'd show a date picker
        filter.timeRange = .lastDay
    }
}

// MARK: - Supporting Cell Classes

final class SwitchTableViewCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let switchControl = UISwitch()
    private var onValueChanged: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .black
        selectionStyle = .none
        
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        
        [titleLabel, switchControl].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: switchControl.leadingAnchor, constant: -8)
        ])
    }
    
    func configure(title: String, isOn: Bool, onValueChanged: @escaping (Bool) -> Void) {
        titleLabel.text = title
        switchControl.isOn = isOn
        self.onValueChanged = onValueChanged
    }
    
    @objc private func switchValueChanged() {
        onValueChanged?(switchControl.isOn)
    }
}

final class TextFieldTableViewCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let textField = UITextField()
    private var onTextChanged: ((String) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .black
        selectionStyle = .none
        
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        
        textField.textColor = .white
        textField.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        textField.layer.cornerRadius = 6
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        [titleLabel, textField].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textField.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configure(title: String, placeholder: String, keyboardType: UIKeyboardType, currentValue: String?, onTextChanged: @escaping (String) -> Void) {
        titleLabel.text = title
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.text = currentValue
        self.onTextChanged = onTextChanged
    }
    
    @objc private func textFieldChanged() {
        onTextChanged?(textField.text ?? "")
    }
} 