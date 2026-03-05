//
//  ObjectExplorerDetailViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025.
//

import UIKit

final class ObjectExplorerDetailViewController: BaseController {

    private let introspector: ObjectIntrospector
    private var sections: [ObjectExplorerSection] = []
    private var filteredProperties: [ObjectProperty] = []
    private var filteredIvars: [ObjectIvar] = []
    private var filteredMethods: [ObjectMethod] = []
    private var isSearching = false

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        return tableView
    }()

    private let searchController = UISearchController(searchResultsController: nil)

    init(object: Any, title: String? = nil) {
        self.introspector = ObjectIntrospector(object: object)
        super.init()
        self.title = title ?? introspector.identity.className
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sections = introspector.availableSections()
        setupTable()
        setupSearch()
    }

    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)

        view.backgroundColor = UIColor.black
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter properties, ivars, methods..."
        searchController.searchBar.barStyle = .black
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    // MARK: - Helpers

    private func isObjectNavigable(_ value: Any?) -> Bool {
        guard let value else { return false }
        return value is NSObject
    }

    private func navigateToObject(_ value: Any?, name: String) {
        guard let value else { return }
        let detail = ObjectExplorerDetailViewController(object: value, title: name)
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ObjectExplorerDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sections[section]
        if isSearching {
            switch sectionType {
            case .properties: return filteredProperties.count
            case .ivars: return filteredIvars.count
            case .methods: return filteredMethods.count
            default: return introspector.numberOfRows(for: sectionType)
            }
        }
        return introspector.numberOfRows(for: sectionType)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = sections[section]
        let count: Int
        if isSearching {
            switch sectionType {
            case .properties: count = filteredProperties.count
            case .ivars: count = filteredIvars.count
            case .methods: count = filteredMethods.count
            default: count = introspector.numberOfRows(for: sectionType)
            }
        } else {
            count = introspector.numberOfRows(for: sectionType)
        }
        return "\(sectionType.title) (\(count))"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        let sectionType = sections[indexPath.section]

        switch sectionType {
        case .identity:
            configureIdentityCell(cell, at: indexPath)
        case .properties:
            let props = isSearching ? filteredProperties : introspector.properties
            if indexPath.row < props.count {
                configurePropertyCell(cell, property: props[indexPath.row])
            }
        case .ivars:
            let ivars = isSearching ? filteredIvars : introspector.ivars
            if indexPath.row < ivars.count {
                configureIvarCell(cell, ivar: ivars[indexPath.row])
            }
        case .methods:
            let methods = isSearching ? filteredMethods : introspector.methods
            if indexPath.row < methods.count {
                configureMethodCell(cell, method: methods[indexPath.row])
            }
        case .superclass:
            configureSuperclassCell(cell, at: indexPath)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionType = sections[indexPath.section]

        switch sectionType {
        case .properties:
            let props = isSearching ? filteredProperties : introspector.properties
            if indexPath.row < props.count {
                let prop = props[indexPath.row]
                if isObjectNavigable(prop.rawValue) {
                    navigateToObject(prop.rawValue, name: prop.name)
                } else {
                    copyToClipboard("\(prop.name): \(prop.value)")
                }
            }
        case .ivars:
            let ivars = isSearching ? filteredIvars : introspector.ivars
            if indexPath.row < ivars.count {
                let ivar = ivars[indexPath.row]
                if isObjectNavigable(ivar.rawValue) {
                    navigateToObject(ivar.rawValue, name: ivar.name)
                } else {
                    copyToClipboard("\(ivar.name): \(ivar.value)")
                }
            }
        case .identity:
            let text: String
            if indexPath.row == 0 {
                text = introspector.identity.className
            } else {
                text = introspector.identity.memoryAddress
            }
            copyToClipboard(text)
        case .methods:
            let methods = isSearching ? filteredMethods : introspector.methods
            if indexPath.row < methods.count {
                copyToClipboard(methods[indexPath.row].name)
            }
        case .superclass:
            if indexPath.row < introspector.identity.superclassChain.count {
                copyToClipboard(introspector.identity.superclassChain[indexPath.row])
            }
        }
    }

    // MARK: - Cell Configuration

    private func configureIdentityCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        if indexPath.row == 0 {
            cell.setup(
                title: "Class",
                description: introspector.identity.className,
                image: nil
            )
        } else {
            cell.setup(
                title: "Address",
                description: introspector.identity.memoryAddress,
                image: nil
            )
        }
    }

    private func configurePropertyCell(_ cell: UITableViewCell, property: ObjectProperty) {
        let subtitle = "\(property.typeName) = \(property.value)"
        let image: UIImage? = isObjectNavigable(property.rawValue) ?
            .named("chevron.right", default: "→") : nil
        cell.setup(
            title: property.name,
            subtitle: subtitle,
            image: image
        )
    }

    private func configureIvarCell(_ cell: UITableViewCell, ivar: ObjectIvar) {
        let subtitle = "\(ivar.typeName) = \(ivar.value)"
        let image: UIImage? = isObjectNavigable(ivar.rawValue) ?
            .named("chevron.right", default: "→") : nil
        cell.setup(
            title: ivar.name,
            subtitle: subtitle,
            image: image
        )
    }

    private func configureMethodCell(_ cell: UITableViewCell, method: ObjectMethod) {
        let subtitle = method.argumentCount > 0 ?
            "\(method.argumentCount) argument(s)" : "no arguments"
        cell.setup(
            title: method.name,
            subtitle: subtitle,
            image: nil
        )
    }

    private func configureSuperclassCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let chain = introspector.identity.superclassChain
        if indexPath.row < chain.count {
            cell.setup(title: chain[indexPath.row], image: nil)
        }
    }

    // MARK: - Clipboard

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        let alert = UIAlertController(title: nil, message: "Copied to clipboard", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension ObjectExplorerDetailViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        isSearching = !query.isEmpty

        if isSearching {
            filteredProperties = introspector.properties.filter {
                $0.name.lowercased().contains(query) ||
                $0.typeName.lowercased().contains(query) ||
                $0.value.lowercased().contains(query)
            }
            filteredIvars = introspector.ivars.filter {
                $0.name.lowercased().contains(query) ||
                $0.typeName.lowercased().contains(query) ||
                $0.value.lowercased().contains(query)
            }
            filteredMethods = introspector.methods.filter {
                $0.name.lowercased().contains(query)
            }
        }

        tableView.reloadData()
    }
}
