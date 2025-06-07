//
//  WebSocket.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit
import SwiftUI

final class WebSocketViewController: BaseController, MainFeatureType {
    var controllerType: DebugSwiftFeature { .network }

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        tableView.estimatedRowHeight = 80
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search connections"
        return searchController
    }()

    private var connections: [WebSocketConnection] = []
    private var filteredConnections: [WebSocketConnection] = []
    private var isSearching = false

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        loadConnections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addNavigationButtons()
        loadConnections()
    }

    private func setup() {
        title = "WebSocket Inspector"
        tabBarItem = UITabBarItem(
            title: "WebSocket",
            image: UIImage(systemName: "globe.americas.fill"),
            tag: 1
        )
        view.backgroundColor = UIColor.black
        setupKeyboardDismissGesture()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.loadConnections()
            }
        }
    }

    private func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    @MainActor
    private func loadConnections() {
        connections = WebSocketDataSource.shared.getConnectionsSortedByActivity()
        applyFilter()
        tableView.reloadData()
        updateNavigationButtons()
    }

    private func applyFilter() {
        if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
            let lowercaseSearch = searchText.lowercased()
            filteredConnections = connections.filter { connection in
                connection.url.absoluteString.lowercased().contains(lowercaseSearch) ||
                connection.channelName?.lowercased().contains(lowercaseSearch) == true
            }
        } else {
            filteredConnections = connections
        }
    }

    private func addNavigationButtons() {
        updateNavigationButtons()
    }

    private func updateNavigationButtons() {
        var rightBarButtons: [UIBarButtonItem] = []

        // Clear all button
        if !connections.isEmpty {
            let clearButton = UIBarButtonItem(
                image: UIImage(systemName: "trash.circle"),
                style: .plain,
                target: self,
                action: #selector(showClearAlert)
            )
            clearButton.tintColor = .systemRed
            rightBarButtons.append(clearButton)
        }

        // Refresh button
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshConnections)
        )
        refreshButton.tintColor = .systemBlue
        rightBarButtons.append(refreshButton)

        navigationItem.rightBarButtonItems = rightBarButtons
    }

    @objc private func showClearAlert() {
        showAlert(
            with: "Warning",
            title: "This action will remove all WebSocket connections and frames",
            leftButtonTitle: "Clear All",
            leftButtonStyle: .destructive,
            leftButtonHandler: { _ in
                Task { @MainActor in
                    WebSocketDataSource.shared.removeAllConnections()
                }
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }

    @objc private func refreshConnections() {
        loadConnections()
    }
}

// MARK: - UISearchResultsUpdating

extension WebSocketViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        isSearching = !(searchController.searchBar.text?.isEmpty ?? true)
        applyFilter()
        tableView.reloadData()
    }
}

// MARK: - UITableView DataSource & Delegate

extension WebSocketViewController: UITableViewDelegate, UITableViewDataSource {
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            WebSocketConnectionTableViewCell.self,
            forCellReuseIdentifier: "WebSocketConnectionCell"
        )

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredConnections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "WebSocketConnectionCell",
            for: indexPath
        ) as! WebSocketConnectionTableViewCell
        
        cell.configure(with: filteredConnections[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let connection = filteredConnections[indexPath.row]
        
        Task { @MainActor in
            // Mark connection as read
            WebSocketDataSource.shared.markConnectionAsRead(connection.id)
            
            // Present frame detail view
            let frameController = WebSocketFrameViewController(connection: connection)
            navigationController?.pushViewController(frameController, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let connection = filteredConnections[indexPath.row]
        
        var actions: [UIContextualAction] = []
        
        // Copy URL action
        let copyAction = UIContextualAction(style: .normal, title: "") { [weak self] _, _, completion in
            UIPasteboard.general.string = connection.url.absoluteString
            
            self?.showAlert(
                with: "URL copied to clipboard",
                title: "Copied!"
            )
            completion(true)
        }
        copyAction.image = UIImage(systemName: "doc.on.doc")
        copyAction.backgroundColor = .systemBlue
        actions.append(copyAction)
        
        // Close connection action (if active)
        if connection.isActive {
            let closeAction = UIContextualAction(style: .destructive, title: "") { [weak self] _, _, completion in
                Task { @MainActor in
                    WebSocketDataSource.shared.forceCloseConnection(connection.id)
                    self?.showAlert(
                        with: "Connection closed",
                        title: "Closed"
                    )
                }
                completion(true)
            }
            closeAction.image = UIImage(systemName: "xmark.circle")
            closeAction.backgroundColor = .systemRed
            actions.append(closeAction)
        }
        
        // Clear frames action
        let clearFramesAction = UIContextualAction(style: .normal, title: "") { [weak self] _, _, completion in
            Task { @MainActor in
                WebSocketDataSource.shared.clearFrames(for: connection.id)
                self?.showAlert(
                    with: "All frames cleared for this connection",
                    title: "Cleared"
                )
            }
            completion(true)
        }
        clearFramesAction.image = UIImage(systemName: "trash")
        clearFramesAction.backgroundColor = .systemOrange
        actions.append(clearFramesAction)
        
        return UISwipeActionsConfiguration(actions: actions)
    }
} 