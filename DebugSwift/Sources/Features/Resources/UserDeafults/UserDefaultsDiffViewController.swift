//
//  UserDefaultsDiffViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois (Defaults Diff) on 16/07/26.
//  Copyright © 2026 apple. All rights reserved.
//

import UIKit

// MARK: - UserDefaults Diff & Undo

/// Table controller that surfaces `UserDefaultsDiffAdapter` changes to the user,
/// with per-row undo and manual snapshot capture.
final class UserDefaultsDiffViewController: BaseTableController {

    // MARK: - State

    private var changes: [DefaultsChange] = []

    private let resnapshotButton = UIBarButtonItem(
        image: UIImage(systemName: "arrow.clockwise"),
        style: .plain,
        target: nil,
        action: nil
    )

    private let snapshotButton = UIBarButtonItem(
        image: UIImage(systemName: "camera.fill"),
        style: .plain,
        target: nil,
        action: nil
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Defaults Diff"
        setupNavigation()
        setupTable()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Setup

    private func setupNavigation() {
        resnapshotButton.target = self
        resnapshotButton.action = #selector(resnapshotTapped)
        resnapshotButton.title = "Re-snapshot"

        snapshotButton.target = self
        snapshotButton.action = #selector(snapshotTapped)
        snapshotButton.title = "Take Snapshot"

        navigationItem.rightBarButtonItems = [snapshotButton, resnapshotButton]
    }

    private func setupTable() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
    }

    // MARK: - Data

    private func reload() {
        changes = UserDefaultsDiffAdapter.shared.changes()
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func resnapshotTapped() {
        UserDefaultsDiffAdapter.shared.snapshotNow()
        reload()
    }

    @objc private func snapshotTapped() {
        UserDefaultsDiffAdapter.shared.snapshotNow()
        reload()
    }

    private func undo(at indexPath: IndexPath) {
        let change = changes[indexPath.row]
        UserDefaultsDiffAdapter.shared.undo(change)
        reload()
    }
}

// MARK: - UITableViewDataSource

extension UserDefaultsDiffViewController {
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        changes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        let change = changes[indexPath.row]
        configure(cell, with: change)
        return cell
    }

    private func configure(_ cell: UITableViewCell, with change: DefaultsChange) {
        cell.textLabel?.text = change.key
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        cell.textLabel?.textColor = .white

        let oldValue = change.oldValue.map { "\($0)" } ?? "—"
        let newValue = change.newValue.map { "\($0)" } ?? "—"
        cell.detailTextLabel?.text = "\(change.kind.title) · old: \(oldValue) → new: \(newValue)"
        cell.detailTextLabel?.textColor = .lightGray
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.numberOfLines = 2

        cell.backgroundColor = .black
        cell.accessoryType = .none
        cell.imageView?.image = UIImage(systemName: change.kind.icon)
        cell.imageView?.tintColor = change.kind.color
    }
}

// MARK: - UITableViewDelegate

extension UserDefaultsDiffViewController {
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let undoAction = UIContextualAction(style: .normal, title: "Undo") { [weak self] _, _, completion in
            self?.undo(at: indexPath)
            completion(true)
        }
        undoAction.image = UIImage(systemName: "arrow.uturn.backward")
        undoAction.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [undoAction])
    }
}

// MARK: - Change Kind Presentation

private extension DefaultsChange.Kind {
    var title: String {
        switch self {
        case .added: "Added"
        case .modified: "Modified"
        case .removed: "Removed"
        }
    }

    var color: UIColor {
        switch self {
        case .added: .systemGreen
        case .modified: .systemBlue
        case .removed: .systemRed
        }
    }

    var icon: String {
        switch self {
        case .added: "plus.circle.fill"
        case .modified: "arrow.left.arrow.right.circle.fill"
        case .removed: "minus.circle.fill"
        }
    }
}
