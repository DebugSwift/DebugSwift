//
//  ClassExplorer.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class ClassExplorerViewController: BaseController {
    
    // MARK: - Properties
    
    private let libraryName: String
    private let clazzName: String
    private let viewModel: ClassExplorerViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
        return tableView
    }()
    
    private lazy var createInstanceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Instance", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(createInstanceTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    
    init(libraryName: String, className: String) {
        self.libraryName = libraryName
        self.clazzName = className
        self.viewModel = ClassExplorerViewModel(className: className)
        super.init()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.loadClassInfo()
    }
    
    // MARK: - Setup
    
    private func setup() {
        title = clazzName
        
        view.addSubview(tableView)
        
        if viewModel.canCreateInstance {
            view.addSubview(createInstanceButton)
            
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: createInstanceButton.topAnchor, constant: -16),
                
                createInstanceButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                createInstanceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                createInstanceButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                createInstanceButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    // MARK: - Actions
    
    @objc private func createInstanceTapped() {
        viewModel.createInstance()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension ClassExplorerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        ClassExplorerViewModel.Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = ClassExplorerViewModel.Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .classInfo:
            return viewModel.classInfo.count
        case .properties:
            return viewModel.properties.count
        case .methods:
            return viewModel.methods.count
        case .instanceState:
            return viewModel.instanceProperties.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        
        guard let sectionType = ClassExplorerViewModel.Section(rawValue: indexPath.section) else {
            return cell
        }
        
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.numberOfLines = 0
        
        switch sectionType {
        case .classInfo:
            let info = viewModel.classInfo[indexPath.row]
            cell.textLabel?.text = "\(info.key): \(info.value)"
            
        case .properties:
            let property = viewModel.properties[indexPath.row]
            cell.textLabel?.text = property.description
            
        case .methods:
            let method = viewModel.methods[indexPath.row]
            cell.textLabel?.text = method.description
            
        case .instanceState:
            let property = viewModel.instanceProperties[indexPath.row]
            cell.textLabel?.text = "\(property.name): \(property.value)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = ClassExplorerViewModel.Section(rawValue: section) else { return nil }
        
        switch sectionType {
        case .classInfo:
            return viewModel.classInfo.isEmpty ? nil : "Class Information"
        case .properties:
            return viewModel.properties.isEmpty ? nil : "Properties (\(viewModel.properties.count))"
        case .methods:
            return viewModel.methods.isEmpty ? nil : "Methods (\(viewModel.methods.count))"
        case .instanceState:
            return viewModel.instanceProperties.isEmpty ? nil : "Instance State"
        }
    }
}

// MARK: - UITableViewDelegate

extension ClassExplorerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
} 