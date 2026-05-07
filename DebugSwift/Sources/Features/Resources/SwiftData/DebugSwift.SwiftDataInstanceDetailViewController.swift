//
//  DebugSwift.SwiftDataInstanceDetailViewController.swift
//  DebugSwift
//
//  Detail view for a single SwiftData model instance — shows all properties.
//

import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataInstanceDetailViewController: BaseController {

    // MARK: - Properties

    private let model: any PersistentModel
    private let modelRegistration: SwiftDataModelRegistration
    private let context: ModelContext

    private var properties: [(label: String, value: String)] = []

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(SwiftDataPropertyCell.self, forCellReuseIdentifier: "PropertyCell")
        return table
    }()

    // MARK: - Init

    init(
        model: any PersistentModel,
        modelRegistration: SwiftDataModelRegistration,
        context: ModelContext
    ) {
        self.model = model
        self.modelRegistration = modelRegistration
        self.context = context
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadProperties()
    }
}

// MARK: - Setup

private extension SwiftDataInstanceDetailViewController {

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
        title = modelRegistration.displayName

        if !SwiftDataManager.shared.readOnlyMode {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(shareProperties)
            )
        }
    }

    func loadProperties() {
        properties = SwiftDataManager.shared.properties(of: model)
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc func shareProperties() {
        let text = properties.map { "\($0.label): \($0.value)" }.joined(separator: "\n")
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(activityVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SwiftDataInstanceDetailViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2                  // Model name + persistent identifier
        case 1: return properties.count   // All reflected properties
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Instance Information"
        case 1: return "Properties (\(properties.count))"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "Model"
                cell.detailTextLabel?.text = modelRegistration.displayName
            } else {
                cell.textLabel?.text = "Identifier"
                let id = model.persistentModelID
                cell.detailTextLabel?.text = "\(id)"
                cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            }
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PropertyCell", for: indexPath) as! SwiftDataPropertyCell
            let prop = properties[indexPath.row]
            cell.configure(label: prop.label, value: prop.value)
            return cell

        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate

extension SwiftDataInstanceDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section == 1 else { return }
        let prop = properties[indexPath.row]

        // Copy value on tap
        UIPasteboard.general.string = prop.value
        showCopiedToast(for: prop.label)
    }

    // MARK: - Helpers

    func showCopiedToast(for label: String) {
        let alert = UIAlertController(
            title: nil,
            message: "Copied \"\(label)\" to clipboard",
            preferredStyle: .alert
        )
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }
}

// MARK: - Property Cell

final class SwiftDataPropertyCell: UITableViewCell {

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        l.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.numberOfLines = 0
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        selectionStyle = .default
        contentView.addSubview(nameLabel)
        contentView.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            nameLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.38),

            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(label: String, value: String) {
        nameLabel.text = label
        valueLabel.text = value.isEmpty ? "(empty)" : value
    }
}

#endif
