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
    private let viewModel: NetworkSessionRequestListViewModel

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
        tableView.tintColor = .systemBlue
        tableView.estimatedRowHeight = 85
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            NetworkTableViewCell.self,
            forCellReuseIdentifier: "NetworkSessionRequestCell"
        )
        return tableView
    }()

    private lazy var emptyStateView = NetworkEmptyStateView(message: "No requests in this session.")

    init(sessionID: UUID, titleText: String) {
        self.viewModel = NetworkSessionRequestListViewModel(sessionID: sessionID)
        super.init()
        title = titleText
    }

    init(viewModel: NetworkSessionRequestListViewModel, titleText: String) {
        self.viewModel = viewModel
        super.init()
        title = titleText
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setup()
        setupNavigation()
        loadRequests()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        updateNavigationButtons()
        loadRequests()
    }

    private func setup() {
        view.addSubview(tableView)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        tableView.allowsMultipleSelectionDuringEditing = true

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupNavigation() {
        updateNavigationButtons()
    }

    private func updateNavigationButtons() {
        if tableView.isEditing {
            let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
            let exportTitle = selectedCount > 0 ? "Export (\(selectedCount))" : "Export"
            let exportButton = UIBarButtonItem(
                title: exportTitle,
                style: .done,
                target: self,
                action: #selector(exportHARTapped)
            )
            exportButton.isEnabled = selectedCount > 0

            let isAllSelected = !viewModel.isEmpty && selectedCount == viewModel.numberOfRequests
            let selectAllImage = UIImage(systemName: isAllSelected ? "checkmark.circle.fill" : "checkmark.circle")
            let toggleSelectAllButton = UIBarButtonItem(
                image: selectAllImage,
                style: .plain,
                target: self,
                action: #selector(toggleSelectAllTapped)
            )
            navigationItem.rightBarButtonItems = [exportButton, toggleSelectAllButton]
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Cancel",
                style: .plain,
                target: self,
                action: #selector(cancelSelectionTapped)
            )
        } else {
            let shareButton = UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(shareTapped)
            )

            let injectionManager = NetworkInjectionManager.shared
            let isInjectionActive = injectionManager.getDelayConfig().isEnabled || 
                                    injectionManager.getFailureConfig().isEnabled ||
                                    injectionManager.getRewriteConfig().isEnabled

            let injectionButton = UIBarButtonItem(
                image: injectionSymbolImage(),
                menu: buildSessionInjectionMenu()
            )
            injectionButton.tintColor = isInjectionActive ? .systemOrange : .systemGray

            navigationItem.rightBarButtonItems = [shareButton, injectionButton]
            navigationItem.leftBarButtonItem = nil
        }
    }

    private func injectionSymbolImage() -> UIImage? {
        if #available(iOS 16.0, *) {
            return UIImage(systemName: "syringe")
        }

        return UIImage(systemName: "pencil")
    }

    private func buildSessionInjectionMenu() -> UIMenu {
        let importAction = UIAction(
            title: "Import to Response Modifier",
            image: UIImage(systemName: "arrow.triangle.2.circlepath")
        ) { [weak self] _ in
            self?.importSessionTapped()
        }

        let advancedAction = UIAction(
            title: "Advanced Settings...",
            image: UIImage(systemName: "gearshape")
        ) { [weak self] _ in
            let settingsController = NetworkInjectionSettingsController()
            self?.navigationController?.pushViewController(settingsController, animated: true)
        }

        return UIMenu(
            title: "Session Injection",
            children: [
                importAction,
                advancedAction
            ]
        )
    }

    @objc private func shareTapped() {
        guard !viewModel.isEmpty else { return }
        tableView.setEditing(true, animated: true)
        for row in 0..<viewModel.numberOfRequests {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
        updateNavigationButtons()
    }

    @objc private func toggleSelectAllTapped() {
        let currentSelectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        let shouldSelectAll = currentSelectedCount < viewModel.numberOfRequests
        for row in 0..<viewModel.numberOfRequests {
            let indexPath = IndexPath(row: row, section: 0)
            if shouldSelectAll {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
        updateNavigationButtons()
    }

    @objc private func cancelSelectionTapped() {
        tableView.setEditing(false, animated: true)
        updateNavigationButtons()
    }

    @objc private func exportHARTapped() {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows, !selectedIndexPaths.isEmpty else { return }
        viewModel.exportHAR(from: selectedIndexPaths)
        cancelSelectionTapped()
    }


    private func loadRequests() {
        Task { @MainActor in
            await viewModel.loadRequests()
            applyFilter()
        }
    }

    private func applyFilter() {
        if tableView.isEditing {
            tableView.setEditing(false, animated: false)
            updateNavigationButtons()
        }
        let query = searchController.searchBar.text ?? ""
        viewModel.applyFilter(query: query)
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        if viewModel.isEmpty {
            tableView.backgroundView = emptyStateView
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

    @objc private func importSessionTapped() {
        guard viewModel.totalRequestsCount > 0 else {
            showMessageAlert(
                title: "No Requests",
                message: "This session does not contain any requests to import."
            )
            return
        }

        let alert = UIAlertController(
            title: "Import Session to Response Modifier?",
            message: "This will delete all existing Response Modifier rules and replace them with \(viewModel.totalRequestsCount) rule(s) from this session.\n\nLong sessions can create many rules and may reduce network matching performance.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Import", style: .destructive) { [weak self] _ in
            self?.importSessionRules()
        })
        present(alert, animated: true)
    }

    private func importSessionRules() {
        let count = viewModel.importSessionRules()
        showMessageAlert(
            title: "Import Complete",
            message: "Replaced existing Response Modifier rules with \(count) rule(s) from this session. Response Modifier is now active."
        )
    }

    private func showMessageAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

@available(iOS 17.0, *)
extension NetworkSessionRequestListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRequests
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = viewModel.request(at: indexPath.row)
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NetworkSessionRequestCell",
            for: indexPath
        ) as! NetworkTableViewCell
        cell.setup(request.makeHttpModel())
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateNavigationButtons()
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let model = viewModel.httpModel(at: indexPath.row)
        let detailController = NetworkViewControllerDetail(model: model)
        navigationController?.pushViewController(detailController, animated: true)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateNavigationButtons()
        }
    }
}

@available(iOS 17.0, *)
extension NetworkSessionRequestListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}
#endif
