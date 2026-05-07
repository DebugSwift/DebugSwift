//
//  LoadedLibraries.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class LoadedLibrariesViewController: BaseController {
    
    // MARK: - Properties
    
    private let viewModel = LoadedLibrariesViewModel()
    private let searchController = UISearchController(searchResultsController: nil)
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
        return tableView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Public", "Private"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var exportButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Export",
            style: .plain,
            target: self,
            action: #selector(exportLibraries)
        )
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCallbacks()
        viewModel.loadLibraries()
    }
    
    // MARK: - Setup
    
    private func setup() {
        title = "Loaded Libraries"
        navigationItem.rightBarButtonItem = exportButton
        
        setupSearchController()
        setupUI()
    }
    
    private func setupCallbacks() {
        viewModel.onLoadingStateChanged = { [weak self] index in
            guard let self = self else { return }
            self.tableView.reloadSections(IndexSet(integer: index), with: .none)
        }
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search libraries or classes"
        searchController.searchBar.tintColor = .white
        searchController.searchBar.barStyle = .black
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupUI() {
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func filterChanged() {
        let filter: LoadedLibrariesViewModel.LibraryFilter
        switch segmentedControl.selectedSegmentIndex {
        case 0: filter = .all
        case 1: filter = .public
        case 2: filter = .private
        default: filter = .all
        }
        viewModel.filterLibraries(by: filter)
        tableView.reloadData()
    }
    
    @objc private func exportLibraries() {
        let report = viewModel.generateReport()
        FileSharingManager.generateFileAndShare(
            text: report,
            fileName: "loaded_libraries_\(Date().timeIntervalSince1970)"
        )
    }
}

// MARK: - UITableViewDataSource

extension LoadedLibrariesViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.filteredLibraries.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let library = viewModel.filteredLibraries[section]
        return library.isExpanded ? library.classes.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        let library = viewModel.filteredLibraries[indexPath.section]
        let className = library.classes[indexPath.row]
        
        cell.textLabel?.text = className
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let library = viewModel.filteredLibraries[section]
        
        let headerView = LibraryHeaderView()
        headerView.configure(with: library)
        headerView.onToggle = { [weak self] in
            self?.viewModel.toggleLibraryExpansion(at: section)
            self?.tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        90
    }
}

// MARK: - UITableViewDelegate

extension LoadedLibrariesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let library = viewModel.filteredLibraries[indexPath.section]
        let className = library.classes[indexPath.row]
        
        let classExplorer = ClassExplorerViewController(
            libraryName: library.name,
            className: className
        )
        navigationController?.pushViewController(classExplorer, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension LoadedLibrariesViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.searchLibraries(with: searchText)
        tableView.reloadData()
    }
} 
