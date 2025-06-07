//
//  Network.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit
import SwiftUI

enum NetworkInspectorMode {
    case http
    case websocket
}

final class NetworkViewController: BaseController, MainFeatureType {
    var controllerType: DebugSwiftFeature { .network }

    private let segmentedControl: UISegmentedControl = {
        let items = ["HTTP", "WebSocket"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemGray6
        control.selectedSegmentTintColor = .systemBlue
        return control
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.estimatedRowHeight = 80
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        return searchController
    }()

    private let viewModel = NetworkViewModel()
    
    // WebSocket-related properties
    private var currentMode: NetworkInspectorMode = .http
    private var webSocketConnections: [WebSocketConnection] = []
    private var filteredWebSocketConnections: [WebSocketConnection] = []

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControl()
        setupTableView()
        setupSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentModeData()
        addNavigationButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewModel.firstIn {
            scrollToBottom()
            viewModel.firstIn = false
        }
    }

    func setup() {
        title = "Network"
        tabBarItem = UITabBarItem(
            title: title,
            image: .named("network"),
            tag: 0
        )
        view.backgroundColor = UIColor.black
        setupKeyboardDismissGesture()
        observers()
    }

    func observers() {
        // HTTP notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "reloadHttp_DebugSwift"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let success = notification.object as? Bool ?? false
            MainActor.assumeIsolated {
                self?.reloadHttp(
                    needScrollToEnd: self?.viewModel.reachEnd ?? true,
                    success: success
                )
            }
        }
        
        // WebSocket notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.loadWebSocketConnections()
            }
        }
    }

    func reloadHttp(needScrollToEnd: Bool = false, success: Bool = true) {
        guard viewModel.reloadDataFinish else { return }
        guard currentMode == .http else { return }

        FloatViewManager.animate(success: success)
        viewModel.applyFilter()
        tableView.reloadData()

        if needScrollToEnd {
            scrollToBottom()
        }
    }
    
    // MARK: - Segmented Control
    
    private func setupSegmentedControl() {
        view.addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    @objc private func segmentedControlChanged() {
        currentMode = segmentedControl.selectedSegmentIndex == 0 ? .http : .websocket
        updateSearchPlaceholder()
        loadCurrentModeData()
        addNavigationButtons()
    }
    
    private func updateSearchPlaceholder() {
        switch currentMode {
        case .http:
            searchController.searchBar.placeholder = "Search requests"
        case .websocket:
            searchController.searchBar.placeholder = "Search connections"
        }
    }
    
    // MARK: - Data Loading
    
    private func loadCurrentModeData() {
        switch currentMode {
        case .http:
            tableView.reloadData()
        case .websocket:
            loadWebSocketConnections()
        }
    }
    
    @MainActor
    private func loadWebSocketConnections() {
        webSocketConnections = WebSocketDataSource.shared.getConnectionsSortedByActivity()
        applyWebSocketFilter()
        tableView.reloadData()
    }
    
    private func applyWebSocketFilter() {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            let lowercaseSearch = searchText.lowercased()
            filteredWebSocketConnections = webSocketConnections.filter { connection in
                connection.url.absoluteString.lowercased().contains(lowercaseSearch) ||
                connection.channelName?.lowercased().contains(lowercaseSearch) == true
            }
        } else {
            filteredWebSocketConnections = webSocketConnections
        }
    }

    private func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func scrollToBottom() {
        if tableView.numberOfSections > 0 {
            let lastSection = tableView.numberOfSections - 1
            let lastRow = tableView.numberOfRows(inSection: lastSection) - 1

            if lastRow >= 0 {
                let indexPath = IndexPath(row: lastRow, section: lastSection)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }

    private func addNavigationButtons() {
        var rightBarButtons: [UIBarButtonItem] = []
        
        switch currentMode {
        case .http:
            // Add threshold button
            let thresholdButton = UIBarButtonItem(
                image: UIImage(systemName: "speedometer"),
                style: .plain,
                target: self,
                action: #selector(showRequestThreshold)
            )
            thresholdButton.tintColor = .systemBlue
            rightBarButtons.append(thresholdButton)
            
            // Add delete button if there are models
            if !viewModel.models.isEmpty {
                let deleteButton = UIBarButtonItem(
                    image: UIImage(systemName: "trash.circle"),
                    style: .plain,
                    target: self,
                    action: #selector(showDeleteAlert)
                )
                deleteButton.tintColor = .systemRed
                rightBarButtons.append(deleteButton)
            }
            
        case .websocket:
            // Clear all WebSocket connections button
            if !webSocketConnections.isEmpty {
                let clearButton = UIBarButtonItem(
                    image: UIImage(systemName: "trash.circle"),
                    style: .plain,
                    target: self,
                    action: #selector(showWebSocketClearAlert)
                )
                clearButton.tintColor = .systemRed
                rightBarButtons.append(clearButton)
            }
            
            // Refresh WebSocket connections button
            let refreshButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(refreshWebSocketConnections)
            )
            refreshButton.tintColor = .systemBlue
            rightBarButtons.append(refreshButton)
        }
        
        navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    @objc private func showDeleteAlert() {
        showAlert(
            with: "Warning",
            title: "This action remove all data",
            leftButtonTitle: "Delete",
            leftButtonStyle: .destructive,
            leftButtonHandler: { _ in
                self.clearAction()
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }

    private func clearAction() {
        viewModel.handleClearAction()
        tableView.reloadData()
    }

    @objc private func showRequestThreshold() {
        let thresholdController = NetworkThresholdController()
        navigationController?.pushViewController(thresholdController, animated: true)
    }
    
    @objc private func showWebSocketClearAlert() {
        showAlert(
            with: "Warning",
            title: "This action will remove all WebSocket connections and frames",
            leftButtonTitle: "Clear All",
            leftButtonStyle: .destructive,
            leftButtonHandler: { _ in
                Task { @MainActor in
                    WebSocketDataSource.shared.removeAllConnections()
                    self.loadWebSocketConnections()
                }
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }
    
    @objc private func refreshWebSocketConnections() {
        loadWebSocketConnections()
    }
}

extension NetworkViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        switch currentMode {
        case .http:
            viewModel.networkSearchWord = searchText
            viewModel.applyFilter()
        case .websocket:
            applyWebSocketFilter()
        }
        
        tableView.reloadData()
    }
}

extension NetworkViewController: UITableViewDelegate, UITableViewDataSource {
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            NetworkTableViewCell.self,
            forCellReuseIdentifier: "NetworkCell"
        )
        tableView.register(
            WebSocketConnectionTableViewCell.self,
            forCellReuseIdentifier: "WebSocketConnectionCell"
        )

        // Configure constraints for the tableView - account for segmented control
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        switch currentMode {
        case .http:
            return viewModel.models.count
        case .websocket:
            return filteredWebSocketConnections.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentMode {
        case .http:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "NetworkCell",
                for: indexPath
            ) as! NetworkTableViewCell
            cell.setup(viewModel.models[indexPath.row])
            return cell
            
        case .websocket:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "WebSocketConnectionCell",
                for: indexPath
            ) as! WebSocketConnectionTableViewCell
            cell.configure(with: filteredWebSocketConnections[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch currentMode {
        case .http:
            let model = viewModel.models[indexPath.row]
            let controller = NetworkViewControllerDetail(model: model)
            navigationController?.pushViewController(controller, animated: true)
            
        case .websocket:
            let connection = filteredWebSocketConnections[indexPath.row]
            
            Task { @MainActor in
                // Mark connection as read
                WebSocketDataSource.shared.markConnectionAsRead(connection.id)
                
                // Present frame detail view
                let frameController = WebSocketFrameViewController(connection: connection)
                navigationController?.pushViewController(frameController, animated: true)
            }
        }
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch currentMode {
        case .http:
            let action = UIContextualAction(style: .normal, title: "") { [weak self] _, _, _ in
                guard let self else { return }

                if let url = self.viewModel.models[indexPath.row].url {
                    UIPasteboard.general.string = url.absoluteString

                    self.showAlert(
                        with: "You can paste this url when needed.",
                        title: "Copied!"
                    )
                }
            }

            action.image = .named("doc.on.doc", default: "Copy")
            action.backgroundColor = .gray

            return UISwipeActionsConfiguration(actions: [action])
            
        case .websocket:
            let connection = filteredWebSocketConnections[indexPath.row]
            
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
                        self?.loadWebSocketConnections()
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
                    self?.loadWebSocketConnections()
                }
                completion(true)
            }
            clearFramesAction.image = UIImage(systemName: "trash")
            clearFramesAction.backgroundColor = .systemOrange
            actions.append(clearFramesAction)
            
            return UISwipeActionsConfiguration(actions: actions)
        }
    }
}
