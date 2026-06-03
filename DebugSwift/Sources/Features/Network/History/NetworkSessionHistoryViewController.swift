//
//  NetworkSessionHistoryViewController.swift
//  DebugSwift
//
//  Created by Adjie Satryo on 16/05/26.
//

import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class NetworkSessionHistoryViewController: BaseController {
    private var sessions: [NetworkSessionPersistenceManager.SessionRecord] = []
    private var activeSessionID: UUID?
    private var isLoading = false
    private var retentionInfoText: String {
        let days = NetworkSessionPersistenceManager.retentionDaysPreference
        return "Session history only preserves the last \(days) day\(days == 1 ? "" : "s") of data."
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NetworkSessionCell")
        return tableView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "No session history available.\n\n\(retentionInfoText)"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Session History"
        setupViews()
        setupNavigationItems()
        loadSessions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        loadSessions()
    }

    private func setupViews() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear All",
            style: .plain,
            target: self,
            action: #selector(clearAllTapped)
        )
        updateNavigationItems()
    }

    private func loadSessions() {
        isLoading = true
        updateNavigationItems()
        Task { @MainActor in
            async let loadedSessions = NetworkSessionPersistenceManager.shared.fetchSessions()
            async let loadedActiveSessionID = NetworkSessionPersistenceManager.shared.activeSessionID()
            sessions = await loadedSessions
            activeSessionID = await loadedActiveSessionID
            isLoading = false
            tableView.reloadData()
            updateEmptyState()
            updateNavigationItems()
        }
    }

    private func updateEmptyState() {
        if sessions.isEmpty {
            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

    private func updateNavigationItems() {
        navigationItem.rightBarButtonItem?.isEnabled = !sessions.isEmpty && !isLoading
    }

    private func sessionSubtitle(_ session: NetworkSessionPersistenceManager.SessionRecord) -> String {
        let requestsCount = session.requestCount
        let countText = requestsCount == 0 ? "No requests" : "\(requestsCount) request\(requestsCount == 1 ? "" : "s")"

        if session.id == activeSessionID {
            return "\(countText) • Active"
        }

        guard let endedAt = session.endedAt else {
            return countText
        }

        let duration = Int(max(endedAt.timeIntervalSince(session.startedAt), 0))
        let durationText = formattedDuration(seconds: duration)
        return "\(countText) • \(durationText)"
    }

    private func formattedDuration(seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    @objc private func clearAllTapped() {
        let alert = UIAlertController(
            title: "Clear All Sessions",
            message: "Are you sure you want to remove all saved sessions? This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.clearAllSessions()
        })
        present(alert, animated: true)
    }

    private func clearAllSessions() {
        isLoading = true
        updateNavigationItems()
        Task { @MainActor in
            await NetworkSessionPersistenceManager.shared.deleteAllSessions()
            loadSessions()
        }
    }

    private func deleteSession(at indexPath: IndexPath) {
        let session = sessions[indexPath.row]
        isLoading = true
        updateNavigationItems()

        Task { @MainActor in
            await NetworkSessionPersistenceManager.shared.deleteSession(id: session.id)
            if activeSessionID == session.id {
                activeSessionID = nil
            }
            sessions.remove(at: indexPath.row)
            isLoading = false
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateEmptyState()
            updateNavigationItems()
        }
    }
}

@available(iOS 17.0, *)
extension NetworkSessionHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sessions.isEmpty ? nil : retentionInfoText
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = sessions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkSessionCell", for: indexPath)

        var content = cell.defaultContentConfiguration()
        content.text = DateFormatter.networkSessionCellTitleFormatter.string(from: session.startedAt)
        content.secondaryText = sessionSubtitle(session)
        content.textProperties.color = .white
        content.secondaryTextProperties.color = .lightGray
        content.secondaryTextProperties.numberOfLines = 2

        cell.backgroundColor = .black
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let session = sessions[indexPath.row]
        let title = DateFormatter.networkSessionNavigationTitleFormatter.string(from: session.startedAt)
        let controller = NetworkSessionRequestListViewController(sessionID: session.id, titleText: title)
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteSession(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

private extension DateFormatter {
    static let networkSessionCellTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy • HH:mm"
        return formatter
    }()

    static let networkSessionNavigationTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()
}
#endif
