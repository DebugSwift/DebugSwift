//
//  Resources.Generic.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class ResourcesGenericController: BaseTableController {
    let viewModel: ResourcesGenericListViewModel

    init(viewModel: ResourcesGenericListViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let backgroundLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = .zero
        return label
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        return searchController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.viewTitle()
        setupTableView()
        setupBackgroundLabel()
        setupSearch()
    }

    func setupTableView() {
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: .cell
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .black
        guard viewModel.numberOfItems() != .zero, viewModel.isDeleteEnable else { return }
        addRightBarButton(
            image: .init(named: "trash.circle"),
            tintColor: .red
        ) { [weak self] in
            self?.showAlert(
                with: "This action remove all data", title: "Warning",
                leftButtonTitle: "delete",
                leftButtonStyle: .destructive,
                leftButtonHandler: { _ in
                    self?.clearAction()
                },
                rightButtonTitle: "cancel",
                rightButtonStyle: .cancel
            )
        }
    }

    func setupSearch() {
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupBackgroundLabel() {
        tableView.backgroundView = backgroundLabel
    }

    private func clearAction() {
        viewModel.handleClearAction()
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        let numberOfItems =
            searchController.isActive ? viewModel.numberOfFilteredItems() : viewModel.numberOfItems()
        backgroundLabel.text = numberOfItems == .zero ? viewModel.emptyListDescriptionString() : ""
        return numberOfItems
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)

        let dataSource =
            searchController.isActive
                ? viewModel.filteredDataSourceForItem(atIndex: indexPath.row)
                : viewModel.dataSourceForItem(atIndex: indexPath.row)

        cell.setup(
            title: dataSource.title,
            subtitle: dataSource.value,
            image: .init(named: "doc.on.doc")
        )

        return cell
    }

    override func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        viewModel.isDeleteEnable
    }

    override func tableView(
        _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete, viewModel.isDeleteEnable {
            viewModel.handleDeleteItemAction(atIndex: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(
        _: UITableView, titleForDeleteConfirmationButtonForRowAt _: IndexPath
    ) -> String? {
        viewModel.isDeleteEnable ? "Delete" : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        let title = cell.textLabel?.text ?? ""
        let contentToCopy = "\(title)"
        UIPasteboard.general.string = contentToCopy

        UIView.animate(
            withDuration: 0.3,
            animations: {
                cell.alpha = 0.5
            }
        ) { _ in
            UIView.animate(withDuration: 0.3) {
                cell.alpha = 1.0
            }
        }
    }
}

extension ResourcesGenericController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        viewModel.filterContentForSearchText(searchText)
        tableView.reloadData()
    }
}

protocol ResourcesGenericListViewModel: AnyObject {
    var isDeleteEnable: Bool { get }

    /// Returns the number of title-value pairs.
    func numberOfItems() -> Int

    /// Returns the number of filtered title-value pairs for search.
    func numberOfFilteredItems() -> Int

    /// Returns a `String` instance that will be used as a title for `Controller` instance.
    func viewTitle() -> String

    /// Provides the data source object for a cell at the given index.
    /// - Parameter index: The index of the cell that needs the data source.
    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String)

    /// Handles tap on the clear button on the navigation bar.
    func handleClearAction()

    /// Handles delete action on the cell at the given index.
    /// - Parameter index: The index of the cell that the user chose to delete.
    func handleDeleteItemAction(atIndex index: Int)

    /// Returns a `String` instance that will be used as text in the background label of the table view.
    func emptyListDescriptionString() -> String

    /// Provides the filtered data source object for a cell at the given index for search.
    /// - Parameter index: The index of the cell that needs the data source.
    func filteredDataSourceForItem(atIndex index: Int) -> (title: String, value: String)

    /// Filters the content based on the search text.
    /// - Parameter searchText: The text to be used for filtering.
    func filterContentForSearchText(_ searchText: String)
}

// Optional

extension ResourcesGenericListViewModel {
    var isDeleteEnable: Bool { true }
}
