//
//  OSLogConsoleViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 12/05/26.
//

import UIKit

@available(iOS 15.0, *)
final class OSLogConsoleViewController: BaseController {
    
    private let viewModel = OSLogConsoleViewModel()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let toggleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "OSLog Capture"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .gray
        return label
    }()
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "OSLog Console"
        
        setupViews()
        setupTableView()
        setupSearchController()
        setupBindings()
        setupToolbar()
        
        toggleSwitch.isOn = viewModel.isCaptureEnabled
        updateStatusLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !viewModel.isCaptureEnabled {
            viewModel.stop()
        }
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        view.addSubview(headerView)
        view.addSubview(tableView)
        
        headerView.addSubview(toggleLabel)
        headerView.addSubview(toggleSwitch)
        headerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            toggleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            toggleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: -10),
            
            toggleSwitch.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            toggleSwitch.centerYAnchor.constraint(equalTo: toggleLabel.centerYAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: toggleLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        toggleSwitch.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        
        // Add toolbar
        setupToolbar()
    }
    
    private func setupToolbar() {
        // Trash button (clear logs)
        let trashButton = UIBarButtonItem(
            image: UIImage(systemName: "trash.circle"),
            style: .plain,
            target: self,
            action: #selector(clearLogs)
        )
        
        // Share/Export button
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(exportLogs)
        )
        
        // Edit/More button
        let editButton = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(showMoreOptions)
        )
        
        navigationItem.rightBarButtonItems = [editButton, shareButton, trashButton]
    }
    
    @objc private func showMoreOptions() {
        let alert = UIAlertController(
            title: "Options",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Clear Logs", style: .destructive) { [weak self] _ in
            self?.clearLogs()
        })
        
        alert.addAction(UIAlertAction(title: "Filter by Subsystem", style: .default) { [weak self] _ in
            self?.showSubsystemPicker()
        })
        
        let appleStatus = viewModel.showAppleSubsystems ? "ON" : "OFF"
        alert.addAction(UIAlertAction(title: "Show Apple Subsystems: \(appleStatus)", style: .default) { [weak self] _ in
            self?.viewModel.toggleAppleSubsystems()
        })
        
        alert.addAction(UIAlertAction(title: "Auto-scroll: \(viewModel.autoScroll ? "ON" : "OFF")", style: .default) { [weak self] _ in
            self?.viewModel.autoScroll.toggle()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(alert, animated: true)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OSLogCell.self, forCellReuseIdentifier: OSLogCell.identifier)
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search logs..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupBindings() {
        viewModel.onUpdate = { [weak self] in
            self?.tableView.reloadData()
            self?.updateStatusLabel()
            
            if self?.viewModel.autoScroll == true {
                self?.scrollToBottom()
            }
        }
        
        viewModel.onLoadingChanged = { [weak self] isLoading in
            self?.updateStatusLabel()
        }
    }
    
    @objc private func toggleChanged() {
        viewModel.isCaptureEnabled = toggleSwitch.isOn
        updateStatusLabel()
        tableView.reloadData()
    }
    
    @objc private func clearLogs() {
        let alert = UIAlertController(
            title: "Clear Logs",
            message: "Are you sure you want to clear all logs?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.viewModel.clear()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func exportLogs() {
        let logs = viewModel.exportLogs()
        
        guard !logs.isEmpty else {
            let alert = UIAlertController(
                title: "No Logs",
                message: "There are no logs to export.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [logs],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
    
    
    private func showSubsystemPicker() {
        let controller = SubsystemPickerViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func updateStatusLabel() {
        let entries = viewModel.getFilteredEntries()
        var status = "\(entries.count) entries"
        
        if viewModel.isCapturing {
            status += " • Recording"
        }
        
        if viewModel.isLoading {
            status += " • Loading..."
        }
        
        statusLabel.text = status
    }
    
    private func scrollToBottom() {
        let entries = viewModel.getFilteredEntries()
        guard !entries.isEmpty else { return }
        
        let indexPath = IndexPath(row: entries.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

@available(iOS 15.0, *)
extension OSLogConsoleViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let entries = viewModel.getFilteredEntries()
        return viewModel.isCaptureEnabled ? entries.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard viewModel.isCaptureEnabled else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "Enable OSLog Capture"
            cell.detailTextLabel?.text = "Toggle the switch above to start capturing os_log / Logger output"
            cell.detailTextLabel?.numberOfLines = 0
            cell.backgroundColor = .black
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .gray
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSLogCell.identifier,
            for: indexPath
        ) as? OSLogCell else {
            return UITableViewCell()
        }
        
        let entries = viewModel.getFilteredEntries()
        let entry = entries[indexPath.row]
        cell.configure(with: entry)
        
        return cell
    }
}

// MARK: - UISearchResultsUpdating

@available(iOS 15.0, *)
extension OSLogConsoleViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text ?? ""
    }
}

// MARK: - OSLogCell

@available(iOS 15.0, *)
private final class OSLogCell: UITableViewCell {
    static let identifier = "OSLogCell"
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let subsystemLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedSystemFont(ofSize: 9, weight: .medium)
        label.textColor = .systemBlue
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubview(timestampLabel)
        contentView.addSubview(subsystemLabel)
        contentView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            subsystemLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 8),
            subsystemLabel.centerYAnchor.constraint(equalTo: timestampLabel.centerYAnchor),
            subsystemLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with entry: OSLogEntry) {
        timestampLabel.text = Self.timeFormatter.string(from: entry.timestamp)
        subsystemLabel.text = entry.subsystem
        subsystemLabel.isHidden = entry.subsystem == nil
        messageLabel.text = entry.message
    }
}

// MARK: - SubsystemPickerViewController

@available(iOS 15.0, *)
private final class SubsystemPickerViewController: BaseController {
    
    private let viewModel: OSLogConsoleViewModel
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        return tableView
    }()
    
    init(viewModel: OSLogConsoleViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Filter Subsystems"
        
        setupViews()
        setupTableView()
        
        // Add clear button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearFilters)
        )
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SubsystemCell")
    }
    
    @objc private func clearFilters() {
        viewModel.selectedSubsystems.removeAll()
        tableView.reloadData()
    }
}

@available(iOS 15.0, *)
extension SubsystemPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.availableSubsystems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubsystemCell", for: indexPath)
        
        let subsystem = viewModel.availableSubsystems[indexPath.row]
        cell.textLabel?.text = subsystem
        cell.textLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .black
        
        if viewModel.selectedSubsystems.contains(subsystem) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let subsystem = viewModel.availableSubsystems[indexPath.row]
        
        if viewModel.selectedSubsystems.contains(subsystem) {
            viewModel.selectedSubsystems.remove(subsystem)
        } else {
            viewModel.selectedSubsystems.insert(subsystem)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
