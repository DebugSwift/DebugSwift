//
//  Performance.ThreadChecker.DetailController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class ThreadViolationDetailViewController: BaseController {
    
    // MARK: - Properties
    
    private let violation: PerformanceThreadChecker.ThreadViolation
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    
    init(violation: PerformanceThreadChecker.ThreadViolation) {
        self.violation = violation
        super.init()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Violation Details"
        view.backgroundColor = .black
        
        // Add share button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareViolation)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupContent() {
        let sections = createSections()
        var previousView: UIView?
        
        for section in sections {
            contentView.addSubview(section)
            section.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                section.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                section.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            
            if let previous = previousView {
                section.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 20).isActive = true
            } else {
                section.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
            }
            
            previousView = section
        }
        
        if let lastView = previousView {
            lastView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
        }
    }
    
    private func createSections() -> [UIView] {
        return [
            createOverviewSection(),
            createDetailsSection(),
            createStackTraceSection(),
            createRecommendationsSection()
        ]
    }
    
    private func createOverviewSection() -> UIView {
        let container = createSectionContainer()
        
        let headerLabel = createSectionHeader("Overview")
        let severityView = createOverviewItem(
            icon: violation.severity.emoji,
            title: "Severity",
            value: violation.severity.rawValue,
            color: violation.severity.color
        )
        let timeView = createOverviewItem(
            icon: "🕒",
            title: "Time",
            value: DateFormatter.localizedString(from: violation.timestamp, dateStyle: .short, timeStyle: .medium),
            color: .lightGray
        )
        
        let stack = UIStackView(arrangedSubviews: [headerLabel, severityView, timeView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    private func createDetailsSection() -> UIView {
        let container = createSectionContainer()
        
        let headerLabel = createSectionHeader("Details")
        let methodView = createDetailRow("Method", value: violation.methodName)
        let classView = createDetailRow("Class", value: violation.className)
        let threadView = createDetailRow("Thread", value: violation.threadName)
        
        let stack = UIStackView(arrangedSubviews: [headerLabel, methodView, classView, threadView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    private func createStackTraceSection() -> UIView {
        let container = createSectionContainer()
        
        let headerLabel = createSectionHeader("Stack Trace")
        
        let stackTraceTextView = UITextView()
        stackTraceTextView.translatesAutoresizingMaskIntoConstraints = false
        stackTraceTextView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        stackTraceTextView.textColor = .lightGray
        stackTraceTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        stackTraceTextView.text = violation.stackTrace.joined(separator: "\n")
        stackTraceTextView.isEditable = false
        stackTraceTextView.layer.cornerRadius = 8
        stackTraceTextView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy Stack Trace", for: .normal)
        copyButton.setTitleColor(.systemBlue, for: .normal)
        copyButton.addTarget(self, action: #selector(copyStackTrace), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [headerLabel, stackTraceTextView, copyButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            
            stackTraceTextView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        return container
    }
    
    private func createRecommendationsSection() -> UIView {
        let container = createSectionContainer()
        
        let headerLabel = createSectionHeader("Recommendations")
        
        let recommendations = getRecommendations()
        var recommendationViews: [UIView] = [headerLabel]
        
        for (index, recommendation) in recommendations.enumerated() {
            let recommendationView = createRecommendationView(
                number: index + 1,
                text: recommendation
            )
            recommendationViews.append(recommendationView)
        }
        
        let stack = UIStackView(arrangedSubviews: recommendationViews)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    // MARK: - Helper Methods
    
    private func createSectionContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return view
    }
    
    private func createSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        return label
    }
    
    private func createOverviewItem(icon: String, title: String, value: String, color: UIColor) -> UIView {
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 20)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .lightGray
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = color
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [iconLabel, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        
        return mainStack
    }
    
    private func createDetailRow(_ title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .lightGray
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .white
        valueLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .top
        
        return stack
    }
    
    private func createRecommendationView(number: Int, text: String) -> UIView {
        let numberLabel = UILabel()
        numberLabel.text = "\(number)."
        numberLabel.font = .systemFont(ofSize: 14, weight: .bold)
        numberLabel.textColor = .systemBlue
        numberLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 14)
        textLabel.textColor = .lightGray
        textLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [numberLabel, textLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .top
        
        return stack
    }
    
    private func getRecommendations() -> [String] {
        switch violation.methodName {
        case "setNeedsLayout", "setNeedsDisplay":
            return [
                "Wrap the UI update in DispatchQueue.main.async { }",
                "Check if you're performing network requests that update UI directly",
                "Consider using @MainActor for the calling function"
            ]
        case "removeFromSuperview", "addSubview":
            return [
                "Always perform view hierarchy changes on the main thread",
                "If called from a background queue, use DispatchQueue.main.async",
                "Consider using weak references to avoid retain cycles"
            ]
        case "viewDidLoad", "viewWillAppear", "viewDidAppear":
            return [
                "Ensure view controller lifecycle methods are called on main thread",
                "Check navigation controller operations",
                "Verify that view controller presentation is on main thread"
            ]
        default:
            return [
                "Ensure all UI operations are performed on the main thread",
                "Use DispatchQueue.main.async for background-to-UI updates",
                "Consider enabling auto-fix mode in Thread Checker settings"
            ]
        }
    }
    
    // MARK: - Actions
    
    @objc private func copyStackTrace() {
        UIPasteboard.general.string = violation.stackTrace.joined(separator: "\n")
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Copied",
            message: "Stack trace copied to clipboard",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func shareViolation() {
        let violationReport = createViolationReport()
        let activityVC = UIActivityViewController(
            activityItems: [violationReport],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
    
    private func createViolationReport() -> String {
        return """
        🧵 Main Thread Violation Report
        
        📋 Overview:
        - Severity: \(violation.severity.emoji) \(violation.severity.rawValue)
        - Time: \(DateFormatter.localizedString(from: violation.timestamp, dateStyle: .short, timeStyle: .medium))
        
        🔍 Details:
        - Method: \(violation.methodName)
        - Class: \(violation.className)
        - Thread: \(violation.threadName)
        
        📚 Stack Trace:
        \(violation.stackTrace.joined(separator: "\n"))
        
        💡 Recommendations:
        \(getRecommendations().enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        Generated by DebugSwift Thread Checker
        """
    }
}

// MARK: - Settings View Controller

final class ThreadCheckerSettingsViewController: BaseTableController {
    
    private enum SettingsSection: Int, CaseIterable {
        case configuration
        case ignoredClasses
        
        var title: String {
            switch self {
            case .configuration: return "Configuration"
            case .ignoredClasses: return "Ignored Classes"
            }
        }
    }
    
    private var ignoredClasses: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        title = "Thread Checker Settings"
        view.backgroundColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissSettings)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveSettings)
        )
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(SwitchCell.self, forCellReuseIdentifier: "SwitchCell")
    }
    
    private func loadSettings() {
        ignoredClasses = Array(PerformanceThreadChecker.shared.ignoredClasses)
        tableView.reloadData()
    }
    
    @objc private func dismissSettings() {
        dismiss(animated: true)
    }
    
    @objc private func saveSettings() {
        PerformanceThreadChecker.shared.ignoredClasses = Set(ignoredClasses)
        dismiss(animated: true)
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SettingsSection(rawValue: section)! {
        case .configuration: return 2
        case .ignoredClasses: return ignoredClasses.count + 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsSection(rawValue: section)?.title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SettingsSection(rawValue: indexPath.section)! {
        case .configuration:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
            if indexPath.row == 0 {
                cell.configure(
                    title: "Show Visual Alerts",
                    isOn: PerformanceThreadChecker.shared.showVisualAlerts
                ) { isOn in
                    PerformanceThreadChecker.shared.showVisualAlerts = isOn
                }
            } else {
                cell.configure(
                    title: "Log to Console",
                    isOn: PerformanceThreadChecker.shared.logToConsole
                ) { isOn in
                    PerformanceThreadChecker.shared.logToConsole = isOn
                }
            }
            return cell
            
        case .ignoredClasses:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.backgroundColor = .clear
            cell.textLabel?.textColor = .white
            
            if indexPath.row < ignoredClasses.count {
                cell.textLabel?.text = ignoredClasses[indexPath.row]
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "Add Class..."
                cell.textLabel?.textColor = .systemBlue
                cell.accessoryType = .none
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch SettingsSection(rawValue: indexPath.section)! {
        case .configuration:
            break
        case .ignoredClasses:
            if indexPath.row < ignoredClasses.count {
                // Edit existing class
                showAddClassAlert(editingIndex: indexPath.row)
            } else {
                // Add new class
                showAddClassAlert()
            }
        }
    }
    
    private func showAddClassAlert(editingIndex: Int? = nil) {
        let title = editingIndex != nil ? "Edit Ignored Class" : "Add Ignored Class"
        let message = "Enter the class name to ignore"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "ClassName"
            if let index = editingIndex {
                textField.text = self.ignoredClasses[index]
            }
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard let className = alert.textFields?.first?.text, !className.isEmpty else { return }
            
            if let index = editingIndex {
                self.ignoredClasses[index] = className
            } else {
                self.ignoredClasses.append(className)
            }
            
            self.tableView.reloadData()
        })
        
        if let index = editingIndex {
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self.ignoredClasses.remove(at: index)
                self.tableView.reloadData()
            })
        }
        
        present(alert, animated: true)
    }
}

// MARK: - Switch Cell

class SwitchCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let switchControl = UISwitch()
    private var onToggle: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16)
        
        switchControl.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, switchControl])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(title: String, isOn: Bool, onToggle: @escaping (Bool) -> Void) {
        titleLabel.text = title
        switchControl.isOn = isOn
        self.onToggle = onToggle
    }
    
    @objc private func switchToggled() {
        onToggle?(switchControl.isOn)
    }
} 