//
//  HeapInstancesController.swift
//  DebugSwift
//
//  Created by Claude Code on 16/08/25.
//

import UIKit

final class HeapInstancesController: BaseController {
    
    // MARK: - Properties
    
    private let className: String
    private let heapBrowser: HeapObjectBrowser
    private var instances: [HeapObjectBrowser.InstanceInfo] = []
    private var isLoading = false
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HeapInstanceCell.self, forCellReuseIdentifier: HeapInstanceCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        return tableView
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No instances found"
        label.textAlignment = .center
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    
    init(className: String, heapBrowser: HeapObjectBrowser) {
        self.className = className
        self.heapBrowser = heapBrowser
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInstances()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = className
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(emptyStateLabel)
        
        // Configure layout
        tableView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading view
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Empty state label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadInstances() {
        guard !isLoading else { return }
        
        isLoading = true
        loadingView.startAnimating()
        tableView.isHidden = true
        emptyStateLabel.isHidden = true
        
        // Load instances on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let instances = self.heapBrowser.getInstances(for: self.className)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadingView.stopAnimating()
                
                self.instances = instances
                
                if instances.isEmpty {
                    self.emptyStateLabel.isHidden = false
                } else {
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension HeapInstancesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instances.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeapInstanceCell.identifier, for: indexPath) as! HeapInstanceCell
        let instance = instances[indexPath.row]
        cell.configure(with: instance)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HeapInstancesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let instance = instances[indexPath.row]
        let detailController = HeapInstanceDetailController(instance: instance)
        
        navigationController?.pushViewController(detailController, animated: true)
    }
}

// MARK: - HeapInstanceCell

private final class HeapInstanceCell: UITableViewCell {
    static let identifier = "HeapInstanceCell"
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let retainCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    private let propertiesCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray2
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
        let mainStackView = UIStackView(arrangedSubviews: [
            addressLabel,
            descriptionLabel
        ])
        mainStackView.axis = .vertical
        mainStackView.spacing = 4
        
        let bottomStackView = UIStackView(arrangedSubviews: [
            retainCountLabel,
            propertiesCountLabel
        ])
        bottomStackView.axis = .horizontal
        bottomStackView.spacing = 16
        
        let fullStackView = UIStackView(arrangedSubviews: [
            mainStackView,
            bottomStackView
        ])
        fullStackView.axis = .vertical
        fullStackView.spacing = 8
        fullStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(fullStackView)
        
        NSLayoutConstraint.activate([
            fullStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            fullStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fullStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fullStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    func configure(with instance: HeapObjectBrowser.InstanceInfo) {
        addressLabel.text = String(format: "0x%016lx", instance.memoryAddress)
        descriptionLabel.text = instance.description
        
        if let retainCount = instance.retainCount {
            retainCountLabel.text = "Retain count: \(retainCount)"
        } else {
            retainCountLabel.text = "Retain count: N/A"
        }
        
        propertiesCountLabel.text = "\(instance.properties.count) properties"
    }
}
