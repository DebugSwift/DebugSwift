//
//  Resources.Generic.Controller.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class ResourcesGenericController: UITableViewController {

    private let titleValueCellIdentifier = "cell"

    let viewModel: ResourcesGenericListViewModel

    init(viewModel: ResourcesGenericListViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .black
    }

    func setupSearch() {
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupBackgroundLabel() {
        tableView.backgroundView = backgroundLabel
    }

    @IBAction func clearButtonAction(_ sender: Any) {
        viewModel.handleClearAction()
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfItems = searchController.isActive ? viewModel.numberOfFilteredItems() : viewModel.numberOfItems()
            backgroundLabel.text = numberOfItems == .zero ? viewModel.emptyListDescriptionString() : ""
            return numberOfItems
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let dataSource = searchController.isActive ?
            viewModel.filteredDataSourceForItem(atIndex: indexPath.row) :
            viewModel.dataSourceForItem(atIndex: indexPath.row)

        cell.setup(
            title: dataSource.title,
            subtitle: dataSource.value,
            image: nil
        )

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                viewModel.handleDeleteItemAction(atIndex: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)

                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
}

extension ResourcesGenericController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // Implement search logic here
        let searchText = searchController.searchBar.text ?? ""
        viewModel.filterContentForSearchText(searchText)
        tableView.reloadData()
    }
}

protocol ResourcesGenericListViewModel: AnyObject {
    /// Returns the number of title-value pairs.
    func numberOfItems() -> Int

    /// Returns the number of filtered title-value pairs for search.
    func numberOfFilteredItems() -> Int

    /// Returns a `String` instance that will be used as a title for `DBTitleValueListTableViewController` instance.
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
