//
//  WebSocketFrameViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class WebSocketFrameViewController: BaseController {
    
    private let connection: WebSocketConnection
    private var frames: [WebSocketFrame] = []
    private var filteredFrames: [WebSocketFrame] = []
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        tableView.estimatedRowHeight = 60
        return tableView
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search in frames"
        return searchController
    }()
    
    private lazy var filterSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Sent", "Received"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.backgroundColor = .darkGray
        control.selectedSegmentTintColor = .systemBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        return control
    }()
    
    private let filterContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private var currentFilter: WebSocketFrameDirection?
    private var isSearching = false
    
    init(connection: WebSocketConnection) {
        self.connection = connection
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchBar()
        loadFrames()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addNavigationButtons()
        loadFrames()
    }
    
    private func setupUI() {
        title = "Frames"
        view.backgroundColor = .black
        
        // Add filter control
        view.addSubview(filterContainerView)
        filterContainerView.addSubview(filterSegmentedControl)
        
        NSLayoutConstraint.activate([
            filterContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filterContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            filterSegmentedControl.centerXAnchor.constraint(equalTo: filterContainerView.centerXAnchor),
            filterSegmentedControl.centerYAnchor.constraint(equalTo: filterContainerView.centerYAnchor),
            filterSegmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: filterContainerView.leadingAnchor, constant: 16),
            filterSegmentedControl.trailingAnchor.constraint(lessThanOrEqualTo: filterContainerView.trailingAnchor, constant: -16),
            filterSegmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            WebSocketFrameTableViewCell.self,
            forCellReuseIdentifier: "WebSocketFrameCell"
        )
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.loadFrames()
            }
        }
    }
    
    @MainActor
    private func loadFrames() {
        guard let updatedConnection = WebSocketDataSource.shared.getConnection(withId: connection.id) else {
            return
        }
        
        frames = updatedConnection.frames
        applyFilter()
        tableView.reloadData()
    }
    
    private func applyFilter() {
        let searchText = searchController.searchBar.text?.lowercased() ?? ""
        
        if isSearching && !searchText.isEmpty {
            filteredFrames = WebSocketDataSource.shared.searchFrames(in: connection.id, query: searchText)
        } else {
            filteredFrames = frames
        }
        
        // Apply direction filter
        if let direction = currentFilter {
            filteredFrames = filteredFrames.filter { $0.direction == direction }
        }
        
        // Sort by timestamp (newest first)
        filteredFrames.sort { $0.timestamp > $1.timestamp }
    }
    
    @objc private func filterChanged() {
        switch filterSegmentedControl.selectedSegmentIndex {
        case 1:
            currentFilter = .sent
        case 2:
            currentFilter = .received
        default:
            currentFilter = nil
        }
        
        applyFilter()
        tableView.reloadData()
    }
    
    private func addNavigationButtons() {
        var rightBarButtons: [UIBarButtonItem] = []
        
        // Clear frames button
        if !frames.isEmpty {
            let clearButton = UIBarButtonItem(
                image: UIImage(systemName: "trash.circle"),
                style: .plain,
                target: self,
                action: #selector(showClearFramesAlert)
            )
            clearButton.tintColor = .systemRed
            rightBarButtons.append(clearButton)
        }
        
        // Connection info button
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showConnectionInfo)
        )
        infoButton.tintColor = .systemBlue
        rightBarButtons.append(infoButton)
        
        navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    @objc private func showClearFramesAlert() {
        showAlert(
            with: "Warning",
            title: "This action will clear all frames for this connection",
            leftButtonTitle: "Clear Frames",
            leftButtonStyle: .destructive,
            leftButtonHandler: { _ in
                Task { @MainActor in
                    WebSocketDataSource.shared.clearFrames(for: self.connection.id)
                }
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }
    
    @objc private func showConnectionInfo() {
        let infoController = WebSocketConnectionInfoViewController(connection: connection)
        let navController = UINavigationController(rootViewController: infoController)
        present(navController, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension WebSocketFrameViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        isSearching = !(searchController.searchBar.text?.isEmpty ?? true)
        applyFilter()
        tableView.reloadData()
    }
}

// MARK: - UITableView DataSource & Delegate

extension WebSocketFrameViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFrames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "WebSocketFrameCell",
            for: indexPath
        ) as! WebSocketFrameTableViewCell
        
        cell.configure(with: filteredFrames[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let frame = filteredFrames[indexPath.row]
        let detailController = WebSocketFrameDetailViewController(frame: frame, connection: connection)
        navigationController?.pushViewController(detailController, animated: true)
    }
} 