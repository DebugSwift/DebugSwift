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
    private var sessions: [NetworkSessionEntity] = []

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
        label.text = "No session history available."
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Session History"
        setupViews()
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

    private func loadSessions() {
        sessions = NetworkSessionPersistenceManager.shared.fetchSessions()
        tableView.reloadData()
        updateEmptyState()
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

    private func sessionSubtitle(_ session: NetworkSessionEntity) -> String {
        let requestsCount = session.requests.count
        let countText = "\(requestsCount) requests"

        guard let endedAt = session.endedAt else {
            let activeText = "Active"
            return "\(countText) • \(activeText)"
        }

        let duration = Int(max(endedAt.timeIntervalSince(session.startedAt), 0))
        let durationText = "\(duration)s"
        return "\(countText) • \(durationText)"
    }
}

@available(iOS 17.0, *)
extension NetworkSessionHistoryViewController: UITableViewDataSource, UITableViewDelegate {
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
