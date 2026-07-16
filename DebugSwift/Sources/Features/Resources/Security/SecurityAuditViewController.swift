//
//  SecurityAuditViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois (Security Audit) on 16/07/26.
//

import UIKit

// MARK: - Secure Storage Audit — findings browser

/// Displays the results of a `SecurityAuditorAdapter` run, grouped by
/// severity so the most actionable findings surface first.
final class SecurityAuditViewController: BaseTableController {

    private enum Section: Int, CaseIterable {
        case critical
        case warning
        case info

        var title: String {
            switch self {
            case .critical: "Critical"
            case .warning: "Warning"
            case .info: "Info"
            }
        }
    }

    private var groupedFindings: [Section: [SecurityFinding]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Security Audit"
        tableView.register(SecurityFindingCell.self, forCellReuseIdentifier: .securityFindingCell)
        runAudit()
    }

    private func runAudit() {
        let findings = SecurityAuditorAdapter.audit()
        groupedFindings = Dictionary(grouping: findings) { finding in
            switch finding.severity {
            case .critical: Section.critical
            case .warning: Section.warning
            case .info: Section.info
            }
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refresh)
        )
        tableView.reloadData()
    }

    @objc private func refresh() {
        runAudit()
    }
}

// MARK: - Data source

extension SecurityAuditViewController {
    override func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        let bucket = Section(rawValue: section) ?? .info
        let count = groupedFindings[bucket]?.count ?? 0
        return "\(bucket.title) (\(count))"
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedFindings[Section(rawValue: section)]?.count ?? 0
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: .securityFindingCell,
            for: indexPath
        ) as? SecurityFindingCell ?? SecurityFindingCell()

        let section = Section(rawValue: indexPath.section) ?? .info
        if let finding = groupedFindings[section]?[indexPath.row] {
            cell.configure(with: finding)
        }
        return cell
    }
}

// MARK: - Finding cell

final class SecurityFindingCell: UITableViewCell {
    private let badgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        return view
    }()

    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let keyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 1
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let header = UIStackView(arrangedSubviews: [sourceLabel, keyLabel])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .firstBaseline

        textStack.addArrangedSubview(header)
        textStack.addArrangedSubview(messageLabel)

        contentView.addSubview(badgeView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            badgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            badgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            badgeView.widthAnchor.constraint(equalToConstant: 8),
            badgeView.heightAnchor.constraint(equalTo: keyLabel.heightAnchor),

            textStack.leadingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        selectionStyle = .none
    }

    func configure(with finding: SecurityFinding) {
        badgeView.backgroundColor = SecurityFindingCell.badgeColor(for: finding.severity)
        sourceLabel.text = finding.source.rawValue.capitalized
        keyLabel.text = finding.key
        messageLabel.text = finding.message
    }

    private static func badgeColor(for severity: SecurityFinding.Severity) -> UIColor {
        switch severity {
        case .critical: .systemRed
        case .warning: .systemOrange
        case .info: .systemBlue
        }
    }
}

private extension String {
    static let securityFindingCell = "SecurityFindingCell"
}
