//
//  Performance.ThreadChecker.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class PerformanceThreadCheckerViewController: BaseTableController {
    
    // MARK: - UI Components
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var enabledSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = PerformanceThreadChecker.shared.isEnabled
        switchControl.addTarget(self, action: #selector(enabledSwitchChanged), for: .valueChanged)
        return switchControl
    }()
    
    private lazy var autoFixSegmentedControl: UISegmentedControl = {
        let items = PerformanceThreadChecker.AutoFixMode.allCases.map { $0.rawValue }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = PerformanceThreadChecker.AutoFixMode.allCases.firstIndex(of: PerformanceThreadChecker.shared.autoFixMode) ?? 1
        control.addTarget(self, action: #selector(autoFixModeChanged), for: .valueChanged)
        if #available(iOS 13.0, *) {
            control.selectedSegmentTintColor = .systemBlue
            control.backgroundColor = .secondarySystemBackground
        }
        return control
    }()
    
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear All", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(clearViolations), for: .touchUpInside)
        return button
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Settings", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        return button
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No thread violations detected"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Properties
    
    private var violations: [PerformanceThreadChecker.ThreadViolation] = []
    private var filteredViolations: [PerformanceThreadChecker.ThreadViolation] = []
    private var filterSeverity: PerformanceThreadChecker.ThreadViolation.Severity?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        loadViolations()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Thread Checker"
        view.backgroundColor = .black
        
        setupTableView()
        setupHeaderView()
        setupEmptyState()
    }
    
    private func setupTableView() {
        tableView.register(ThreadViolationCell.self, forCellReuseIdentifier: "ThreadViolationCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorColor = .darkGray
    }
    
    private func setupHeaderView() {
        let headerContainer = UIView()
        headerContainer.backgroundColor = .black
        
        // Enabled label and switch
        let enabledLabel = UILabel()
        enabledLabel.text = "Thread Checker"
        enabledLabel.textColor = .white
        enabledLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        let enabledStack = UIStackView(arrangedSubviews: [enabledLabel, enabledSwitch])
        enabledStack.axis = .horizontal
        enabledStack.spacing = 8
        enabledStack.alignment = .center
        
        // Auto-fix mode label and control
        let autoFixLabel = UILabel()
        autoFixLabel.text = "Mode"
        autoFixLabel.textColor = .lightGray
        autoFixLabel.font = .systemFont(ofSize: 14)
        
        // Button stack
        let buttonStack = UIStackView(arrangedSubviews: [settingsButton, clearButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        
        // Main stack
        let mainStack = UIStackView(arrangedSubviews: [
            enabledStack,
            autoFixLabel,
            autoFixSegmentedControl,
            buttonStack
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        headerContainer.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -16)
        ])
        
        headerContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 160)
        tableView.tableHeaderView = headerContainer
    }
    
    private func setupEmptyState() {
        tableView.backgroundView = emptyStateLabel
    }
    
    private func setupNotifications() {
        PerformanceThreadChecker.shared.onViolationDetected { [weak self] violation in
            DispatchQueue.main.async {
                self?.addViolation(violation)
            }
        }
    }
    
    // MARK: - Data Management
    
    private func loadViolations() {
        violations = PerformanceThreadChecker.shared.getViolations()
        applyFilters()
        updateEmptyState()
    }
    
    private func addViolation(_ violation: PerformanceThreadChecker.ThreadViolation) {
        violations.insert(violation, at: 0)
        applyFilters()
        updateEmptyState()
        
        // Animate insertion if visible
        if !filteredViolations.isEmpty {
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        } else {
            tableView.reloadData()
        }
    }
    
    private func applyFilters() {
        if let filterSeverity = filterSeverity {
            filteredViolations = violations.filter { $0.severity == filterSeverity }
        } else {
            filteredViolations = violations
        }
    }
    
    private func updateEmptyState() {
        let hasViolations = !filteredViolations.isEmpty
        emptyStateLabel.isHidden = hasViolations
        
        if !hasViolations {
            emptyStateLabel.text = PerformanceThreadChecker.shared.isEnabled ? 
                "No thread violations detected" : 
                "Thread Checker is disabled\nEnable it to detect violations"
        }
    }
    
    // MARK: - Actions
    
    @objc private func enabledSwitchChanged() {
        PerformanceThreadChecker.shared.isEnabled = enabledSwitch.isOn
        updateEmptyState()
    }
    
    @objc private func autoFixModeChanged() {
        let selectedMode = PerformanceThreadChecker.AutoFixMode.allCases[autoFixSegmentedControl.selectedSegmentIndex]
        PerformanceThreadChecker.shared.autoFixMode = selectedMode
    }
    
    @objc private func clearViolations() {
        let alert = UIAlertController(
            title: "Clear All Violations",
            message: "Are you sure you want to clear all recorded thread violations?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.violations.removeAll()
            self.filteredViolations.removeAll()
            PerformanceThreadChecker.shared.clearViolations()
            self.tableView.reloadData()
            self.updateEmptyState()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func showSettings() {
        let settingsVC = ThreadCheckerSettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    @objc private func filterBySeverity() {
        let alert = UIAlertController(title: "Filter by Severity", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "All", style: .default) { _ in
            self.filterSeverity = nil
            self.applyFilters()
            self.tableView.reloadData()
        })
        
        for severity in PerformanceThreadChecker.ThreadViolation.Severity.allCases {
            alert.addAction(UIAlertAction(title: "\(severity.emoji) \(severity.rawValue)", style: .default) { _ in
                self.filterSeverity = severity
                self.applyFilters()
                self.tableView.reloadData()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
}

// MARK: - Table View Data Source

extension PerformanceThreadCheckerViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredViolations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadViolationCell", for: indexPath) as! ThreadViolationCell
        let violation = filteredViolations[indexPath.row]
        cell.configure(with: violation)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let violation = filteredViolations[indexPath.row]
        showViolationDetails(violation)
    }
    
    private func showViolationDetails(_ violation: PerformanceThreadChecker.ThreadViolation) {
        let detailVC = ThreadViolationDetailViewController(violation: violation)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Thread Violation Cell

class ThreadViolationCell: UITableViewCell {
    
    private lazy var severityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        return label
    }()
    
    private lazy var methodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private lazy var classLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var threadLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemBlue
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .darkGray
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .gray
        
        let contentStack = UIStackView(arrangedSubviews: [methodLabel, classLabel, threadLabel])
        contentStack.axis = .vertical
        contentStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [severityLabel, contentStack, timeLabel])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .top
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            severityLabel.widthAnchor.constraint(equalToConstant: 30),
            timeLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func configure(with violation: PerformanceThreadChecker.ThreadViolation) {
        severityLabel.text = violation.severity.emoji
        methodLabel.text = violation.methodName
        classLabel.text = violation.className
        threadLabel.text = violation.threadName
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        timeLabel.text = formatter.string(from: violation.timestamp)
    }
} 