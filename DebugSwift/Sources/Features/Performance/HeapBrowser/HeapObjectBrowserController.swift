//
//  HeapObjectBrowserController.swift
//  DebugSwift
//
//  Created by Claude Code on 16/08/25.
//

import UIKit

final class HeapObjectBrowserController: BaseController {
    
    // MARK: - UI Components
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search classes..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    private lazy var sortSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Count", "Name", "Memory"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(sortOptionChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var refreshButton: UIBarButtonItem = {
        UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HeapClassCell.self, forCellReuseIdentifier: HeapClassCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        return tableView
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    
    private let heapBrowser = HeapObjectBrowser()
    private var allClasses: [HeapObjectBrowser.ClassInfo] = []
    private var filteredClasses: [HeapObjectBrowser.ClassInfo] = []
    private var isLoading = false
    private var sortAscending = false
    
    private var currentSortOption: HeapObjectBrowser.SortOption {
        switch sortSegmentedControl.selectedSegmentIndex {
        case 0: return .instanceCount
        case 1: return .className
        case 2: return .memoryFootprint
        default: return .instanceCount
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadHeapData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Heap Object Browser"
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationItem.rightBarButtonItem = refreshButton
        
        // Stack view for controls
        let controlsStack = UIStackView(arrangedSubviews: [
            searchBar,
            sortSegmentedControl
        ])
        controlsStack.axis = .vertical
        controlsStack.spacing = 8
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(controlsStack)
        view.addSubview(tableView)
        view.addSubview(loadingView)
        
        // Configure layout
        tableView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Controls stack
            controlsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading view
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadHeapData() {
        guard !isLoading else { return }
        
        isLoading = true
        loadingView.startAnimating()
        tableView.isHidden = true
        
        // Perform heap scan on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let classes = self.heapBrowser.scanHeapForClasses()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadingView.stopAnimating()
                self.tableView.isHidden = false
                
                self.allClasses = classes
                self.applyFiltersAndSort()
            }
        }
    }
    
    private func applyFiltersAndSort() {
        let searchText = searchBar.text ?? ""
        filteredClasses = heapBrowser.filterClasses(allClasses, searchText: searchText)
        heapBrowser.sortClasses(&filteredClasses, by: currentSortOption, ascending: sortAscending)
        
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func refreshTapped() {
        loadHeapData()
    }
    
    @objc private func sortOptionChanged() {
        applyFiltersAndSort()
    }
}

// MARK: - UITableViewDataSource

extension HeapObjectBrowserController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredClasses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeapClassCell.identifier, for: indexPath) as! HeapClassCell
        let classInfo = filteredClasses[indexPath.row]
        cell.configure(with: classInfo)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HeapObjectBrowserController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let classInfo = filteredClasses[indexPath.row]
        let instancesController = HeapInstancesController(
            className: classInfo.className,
            heapBrowser: heapBrowser
        )
        
        navigationController?.pushViewController(instancesController, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension HeapObjectBrowserController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFiltersAndSort()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - HeapClassCell

private final class HeapClassCell: UITableViewCell {
    static let identifier = "HeapClassCell"
    
    private let classNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 1
        return label
    }()
    
    private let instanceCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let memoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [
            classNameLabel,
            instanceCountLabel,
            memoryLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    func configure(with classInfo: HeapObjectBrowser.ClassInfo) {
        classNameLabel.text = classInfo.className
        instanceCountLabel.text = "\(classInfo.instanceCount) instances"
        memoryLabel.text = ByteCountFormatter.string(fromByteCount: Int64(classInfo.memoryFootprint), countStyle: .memory)
    }
}