//
//  Accessibility.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 07/03/26.
//

import UIKit

final class AccessibilityViewController: BaseController {
    
    private var currentReport: AuditReport?
    private var filteredIssues: [AccessibilityIssue] = []
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        return view
    }()
    
    private lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var wcagLevelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Scan Now", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var exportButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Export Report", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .black
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var filterSegmentedControl: UISegmentedControl = {
        let items = ["All", "Critical", "High", "Medium", "Low"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        performInitialScan()
    }
    
    private func setupUI() {
        title = "Accessibility Auditor"
        view.backgroundColor = .black
        
        view.addSubview(headerView)
        headerView.addSubview(scoreLabel)
        headerView.addSubview(wcagLevelLabel)
        headerView.addSubview(summaryLabel)
        headerView.addSubview(scanButton)
        headerView.addSubview(exportButton)
        headerView.addSubview(filterSegmentedControl)
        view.addSubview(tableView)
        
        tableView.register(AccessibilityIssueCell.self, forCellReuseIdentifier: AccessibilityIssueCell.identifier)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            scoreLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            scoreLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            wcagLevelLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            wcagLevelLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            summaryLabel.topAnchor.constraint(equalTo: wcagLevelLabel.bottomAnchor, constant: 12),
            summaryLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            summaryLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            scanButton.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 16),
            scanButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            scanButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            scanButton.heightAnchor.constraint(equalToConstant: 44),
            
            exportButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 8),
            exportButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            exportButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            exportButton.heightAnchor.constraint(equalToConstant: 44),
            
            filterSegmentedControl.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 16),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            filterSegmentedControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func performInitialScan() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performScan()
        }
    }
    
    @objc private func scanButtonTapped() {
        performScan()
    }
    
    private func performScan() {
        let auditor = AccessibilityAuditor.shared
        let report = auditor.auditCurrentScreen()
        currentReport = report
        updateUI(with: report)
    }
    
    private func updateUI(with report: AuditReport) {
        scoreLabel.text = "\(report.score)"
        scoreLabel.textColor = colorForScore(report.score)
        wcagLevelLabel.text = "\(report.wcagLevel.emoji) \(report.wcagLevel.rawValue)"
        
        let issueText = report.issues.count == 1 ? "issue" : "issues"
        summaryLabel.text = """
        \(report.issues.count) \(issueText) found
        \(report.criticalCount) critical, \(report.highCount) high, \(report.mediumCount) medium, \(report.lowCount) low
        """
        
        exportButton.isHidden = report.issues.isEmpty
        
        applyFilter()
    }
    
    private func applyFilter() {
        guard let report = currentReport else { return }
        
        if filterSegmentedControl.selectedSegmentIndex == 0 {
            filteredIssues = report.issues
        } else {
            let severity: AccessibilityIssueSeverity
            switch filterSegmentedControl.selectedSegmentIndex {
            case 1: severity = .critical
            case 2: severity = .high
            case 3: severity = .medium
            case 4: severity = .low
            default: severity = .critical
            }
            filteredIssues = report.issues.filter { $0.severity == severity }
        }
        
        tableView.reloadData()
    }
    
    @objc private func filterChanged() {
        applyFilter()
    }
    
    @objc private func exportButtonTapped() {
        guard let reportData = AccessibilityAuditor.shared.exportReport(),
              let reportString = String(data: reportData, encoding: .utf8) else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [reportString],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    private func colorForScore(_ score: Int) -> UIColor {
        switch score {
        case 95...100: return .systemGreen
        case 80...94: return .systemBlue
        case 60...79: return .systemOrange
        default: return .systemRed
        }
    }
}

extension AccessibilityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredIssues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AccessibilityIssueCell.identifier, for: indexPath) as? AccessibilityIssueCell else {
            return UITableViewCell()
        }
        
        let issue = filteredIssues[indexPath.row]
        cell.configure(with: issue)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if filteredIssues.isEmpty {
            return nil
        }
        
        let issueText = filteredIssues.count == 1 ? "Issue" : "Issues"
        return "\(filteredIssues.count) \(issueText)"
    }
}

extension AccessibilityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let issue = filteredIssues[indexPath.row]
        let detailVC = AccessibilityIssueDetailViewController(issue: issue)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

final class AccessibilityIssueCell: UITableViewCell {
    static let identifier = "AccessibilityIssueCell"
    
    private lazy var severityIconLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24)
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.numberOfLines = 1
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
        backgroundColor = .black
        contentView.addSubview(severityIconLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(locationLabel)
        
        NSLayoutConstraint.activate([
            severityIconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            severityIconLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            severityIconLabel.widthAnchor.constraint(equalToConstant: 32),
            
            titleLabel.leadingAnchor.constraint(equalTo: severityIconLabel.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            locationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            locationLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            locationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with issue: AccessibilityIssue) {
        severityIconLabel.text = issue.severity.emoji
        titleLabel.text = issue.type.rawValue
        descriptionLabel.text = issue.description
        locationLabel.text = issue.location.isEmpty ? issue.elementDescription : issue.location
    }
}
