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
    case webview
}

final class NetworkViewController: BaseController, MainFeatureType {
    var controllerType: DebugSwiftFeature { .network }

    private let segmentedControl: UISegmentedControl = {
        let items = ["HTTP", "WebSocket", "WebView"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemGray6
        control.selectedSegmentTintColor = .systemBlue
        return control
    }()

    // New HTTP Statistics Header
    private let httpStatsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let totalRequestsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        return label
    }()
    
    private let successRateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .systemGreen
        label.textAlignment = .center
        return label
    }()
    
    private let avgResponseTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .systemOrange
        label.textAlignment = .center
        return label
    }()
    
    private let totalTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .systemPurple
        label.textAlignment = .center
        return label
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.estimatedRowHeight = 85
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        return searchController
    }()

    // Advanced filtering
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 18
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var currentFilter: HTTPRequestFilter = HTTPRequestFilter()

    private let viewModel = NetworkViewModel()
    
    // WebSocket-related properties
    private var currentMode: NetworkInspectorMode = .http
    private var webSocketConnections: [WebSocketConnection] = []
    private var filteredWebSocketConnections: [WebSocketConnection] = []
    
    // Statistics update timer
    private var statsUpdateTimer: Timer?

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControl()
        setupHTTPStatsView()
        setupTableView()
        setupSearchBar()
        setupFilterButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentModeData()
        addNavigationButtons()
        startStatsTimer()
        updateFilterButtonAppearance()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopStatsTimer()
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
                self?.updateHTTPStatistics()
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
        guard currentMode == .http || currentMode == .webview else { return }

        FloatViewManager.animate(success: success)
        viewModel.applyFilter(for: currentMode)
        applyAdvancedFilter()
        tableView.reloadData()

        if needScrollToEnd {
            scrollToBottom()
        }
    }
    
    // MARK: - HTTP Statistics
    
    private func setupHTTPStatsView() {
        view.addSubview(httpStatsView)
        
        let stackView = UIStackView(arrangedSubviews: [
            createStatView(titleLabel: UILabel(), valueLabel: totalRequestsLabel, title: "Total"),
            createStatView(titleLabel: UILabel(), valueLabel: successRateLabel, title: "Success"),
            createStatView(titleLabel: UILabel(), valueLabel: avgResponseTimeLabel, title: "Avg Time"),
            createStatView(titleLabel: UILabel(), valueLabel: totalTimeLabel, title: "Total Time")
        ])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        httpStatsView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            httpStatsView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            httpStatsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            httpStatsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60), // Leave space for filter button
            httpStatsView.heightAnchor.constraint(equalToConstant: 50),
            
            stackView.topAnchor.constraint(equalTo: httpStatsView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: httpStatsView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: httpStatsView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: httpStatsView.bottomAnchor, constant: -8)
        ])
    }
    
    private func createStatView(titleLabel: UILabel, valueLabel: UILabel, title: String) -> UIView {
        let containerView = UIView()
        
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = .lightGray
        titleLabel.textAlignment = .center
        
        valueLabel.textAlignment = .center
        
        [titleLabel, valueLabel].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func updateHTTPStatistics() {
        // Use appropriate data based on current mode
        let requests = currentMode == .webview ? viewModel.webViewModels : viewModel.httpModels
        
        // Total requests
        totalRequestsLabel.text = "\(requests.count)"
        
        // Success rate
        let successCount = requests.filter { $0.isSuccess }.count
        let successRate = requests.isEmpty ? 0 : (Double(successCount) / Double(requests.count)) * 100
        successRateLabel.text = String(format: "%.1f%%", successRate)
        
        // Average response time
        let durations = requests.compactMap { request -> Double? in
            guard let duration = request.totalDuration else { return nil }
            return Double(duration.replacingOccurrences(of: " (s)", with: ""))
        }
        
        if !durations.isEmpty {
            let avgDuration = durations.reduce(0, +) / Double(durations.count)
            if avgDuration < 1.0 {
                avgResponseTimeLabel.text = String(format: "%.0fms", avgDuration * 1000)
            } else {
                avgResponseTimeLabel.text = String(format: "%.2fs", avgDuration)
            }
        } else {
            avgResponseTimeLabel.text = "0ms"
        }
        
        // Total time
        if !durations.isEmpty {
            let totalTime = durations.reduce(0, +)
            if totalTime < 1.0 {
                totalTimeLabel.text = String(format: "%.0fms", totalTime * 1000)
            } else {
                totalTimeLabel.text = String(format: "%.2fs", totalTime)
            }
        } else {
            totalTimeLabel.text = "0ms"
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func startStatsTimer() {
        statsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                if self?.currentMode == .http || self?.currentMode == .webview {
                    self?.updateHTTPStatistics()
                }
            }
        }
    }
    
    private func stopStatsTimer() {
        statsUpdateTimer?.invalidate()
        statsUpdateTimer = nil
    }
    
    // MARK: - Advanced Filtering
    
    private func setupFilterButton() {
        view.addSubview(filterButton)
        filterButton.addTarget(self, action: #selector(showFilterOptions), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            filterButton.leadingAnchor.constraint(equalTo: httpStatsView.trailingAnchor, constant: 8),
            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterButton.centerYAnchor.constraint(equalTo: httpStatsView.centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 36),
            filterButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    @objc private func showFilterOptions() {
        let filterController = HTTPFilterController(currentFilter: currentFilter) { [weak self] newFilter in
            self?.currentFilter = newFilter
            self?.applyAdvancedFilter()
            self?.updateFilterButtonAppearance()
            self?.tableView.reloadData()
        }
        
        let navController = UINavigationController(rootViewController: filterController)
        present(navController, animated: true)
    }
    
    private func updateFilterButtonAppearance() {
        UIView.animate(withDuration: 0.2) {
            if self.currentFilter.isActive {
                self.filterButton.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle.fill"), for: .normal)
                self.filterButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                self.filterButton.tintColor = .systemBlue
                self.filterButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                self.filterButton.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
                self.filterButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
                self.filterButton.tintColor = .systemBlue
                self.filterButton.transform = CGAffineTransform.identity
            }
        }
    }
    
    private func applyAdvancedFilter() {
        guard currentMode == .http || currentMode == .webview else { return }
        
        viewModel.applyAdvancedFilter(currentFilter, for: currentMode)
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
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            currentMode = .http
        case 1:
            currentMode = .websocket
        case 2:
            currentMode = .webview
        default:
            currentMode = .http
        }
        updateSearchPlaceholder()
        updateVisibilityForMode()
        loadCurrentModeData()
        addNavigationButtons()
    }
    
    private func updateVisibilityForMode() {
        UIView.animate(withDuration: 0.3) {
            self.httpStatsView.isHidden = self.currentMode != .http && self.currentMode != .webview
            self.filterButton.isHidden = self.currentMode != .http && self.currentMode != .webview
        }
    }
    
    private func updateSearchPlaceholder() {
        switch currentMode {
        case .http:
            searchController.searchBar.placeholder = "Search requests"
        case .websocket:
            searchController.searchBar.placeholder = "Search connections"
        case .webview:
            searchController.searchBar.placeholder = "Search WebView requests"
        }
    }
    
    // MARK: - Data Loading
    
    private func loadCurrentModeData() {
        switch currentMode {
        case .http:
            viewModel.applyFilter(for: .http)
            updateHTTPStatistics()
            tableView.reloadData()
        case .websocket:
            loadWebSocketConnections()
        case .webview:
            viewModel.applyFilter(for: .webview)
            updateHTTPStatistics() // WebView requests use HTTP statistics
            tableView.reloadData()
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
        case .http, .webview:
            // Add encryption toggle button
            let encryptionButton = UIBarButtonItem(
                image: UIImage(systemName: DebugSwift.Network.shared.isDecryptionEnabled ? "lock.open" : "lock"),
                style: .plain,
                target: self,
                action: #selector(toggleEncryptionDecryption)
            )
            encryptionButton.tintColor = DebugSwift.Network.shared.isDecryptionEnabled ? .systemGreen : .systemGray
            rightBarButtons.append(encryptionButton)
            
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
        let dataType = currentMode == .webview ? "WebView requests" : "HTTP requests"
        showAlert(
            with: "Warning",
            title: "This action will remove all \(dataType)",
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
        viewModel.handleClearAction(for: currentMode)
        tableView.reloadData()
    }

    @objc private func showRequestThreshold() {
        let thresholdController = NetworkThresholdController()
        navigationController?.pushViewController(thresholdController, animated: true)
    }
    
    @objc internal func toggleEncryptionDecryption() {
        DebugSwift.Network.shared.setDecryptionEnabled(!DebugSwift.Network.shared.isDecryptionEnabled)
        addNavigationButtons()
        
        showAlert(
            with: "Encryption Decryption",
            title: DebugSwift.Network.shared.isDecryptionEnabled ? 
                "Decryption enabled. Encrypted responses will be automatically decrypted." : 
                "Decryption disabled. Only raw responses will be shown.",
            rightButtonTitle: "OK"
        )
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
        case .http, .webview:
            viewModel.networkSearchWord = searchText
            viewModel.applyFilter(for: currentMode)
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

        // Configure constraints for the tableView - account for segmented control and stats
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: httpStatsView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        switch currentMode {
        case .http, .webview:
            return viewModel.models.count
        case .websocket:
            return filteredWebSocketConnections.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentMode {
        case .http, .webview:
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
        case .http, .webview:
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
        case .http, .webview:
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
