//
//  NetworkSessionRequestListViewController.swift
//  DebugSwift
//
//  Created by Adjie Satryo on 16/05/26.
//

import UIKit

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class NetworkSessionRequestListViewController: BaseController {
    private let sessionID: UUID
    private var requests: [NetworkRequestEntity] = []
    private var filteredRequests: [NetworkRequestEntity] = []

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search requests"
        return searchController
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.estimatedRowHeight = 85
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            NetworkTableViewCell.self,
            forCellReuseIdentifier: "NetworkSessionRequestCell"
        )
        return tableView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "No requests in this session."
        return label
    }()

    init(sessionID: UUID, titleText: String) {
        self.sessionID = sessionID
        super.init()
        title = titleText
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setup()
        loadRequests()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        loadRequests()
    }

    private func setup() {
        view.addSubview(tableView)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadRequests() {
        requests = NetworkSessionPersistenceManager.shared.fetchRequests(for: sessionID)
        applyFilter()
    }

    private func applyFilter() {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else {
            filteredRequests = requests
            tableView.reloadData()
            updateEmptyState()
            return
        }

        let lowercaseQuery = query.lowercased()
        filteredRequests = requests.filter { request in
            let url = request.url?.lowercased() ?? ""
            let method = request.method?.lowercased() ?? ""
            let statusCode = request.statusCode?.lowercased() ?? ""
            return url.contains(lowercaseQuery) ||
                method.contains(lowercaseQuery) ||
                statusCode.contains(lowercaseQuery)
        }

        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        if filteredRequests.isEmpty {
            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
}

@available(iOS 17.0, *)
extension NetworkSessionRequestListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredRequests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = filteredRequests[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NetworkSessionRequestCell",
            for: indexPath
        ) as! NetworkTableViewCell
        cell.setup(request.makeHttpModel())
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let request = filteredRequests[indexPath.row]
        let detailController = NetworkViewControllerDetail(model: request.makeHttpModel())
        navigationController?.pushViewController(detailController, animated: true)
    }
}

@available(iOS 17.0, *)
extension NetworkSessionRequestListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}
#endif
