//
//  HeadersViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 14/01/26.
//

import UIKit

final class HeadersViewController: BaseTableController {
    private let headers: [(key: String, value: String, isJSON: Bool, itemCount: Int)]
    private var filteredHeaders: [(key: String, value: String, isJSON: Bool, itemCount: Int)]
    private let headerTitle: String
    private var searchController: UISearchController?
    
    init(headers: [String: Any]?, title: String) {
        self.headerTitle = title
        self.headers = headers?.map { 
            let valueString = "\($0.value)"
            let isJSON = Self.isValidJSON(valueString)
            let itemCount = isJSON ? Self.countJSONItems(valueString) : 0
            return (key: $0.key, value: valueString, isJSON: isJSON, itemCount: itemCount)
        }
        .sorted { $0.key.lowercased() < $1.key.lowercased() } ?? []
        self.filteredHeaders = self.headers
        super.init()
    }
    
    private static func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) != nil
    }
    
    private static func countJSONItems(_ string: String) -> Int {
        guard let data = string.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return 0
        }
        
        if let dictionary = jsonObject as? [String: Any] {
            return flattenJSONCount(dictionary: dictionary)
        } else if let array = jsonObject as? [Any] {
            return flattenJSONArrayCount(array: array)
        }
        
        return 0
    }
    
    private static func flattenJSONCount(dictionary: [String: Any]) -> Int {
        var count = 0
        for (_, value) in dictionary {
            if let dict = value as? [String: Any] {
                count += flattenJSONCount(dictionary: dict)
            } else if let array = value as? [Any] {
                count += flattenJSONArrayCount(array: array)
            } else {
                count += 1
            }
        }
        return count
    }
    
    private static func flattenJSONArrayCount(array: [Any]) -> Int {
        var count = 0
        for item in array {
            if let dict = item as? [String: Any] {
                count += flattenJSONCount(dictionary: dict)
            } else if let nestedArray = item as? [Any] {
                count += flattenJSONArrayCount(array: nestedArray)
            } else {
                count += 1
            }
        }
        return count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = headerTitle
        tableView.register(HeaderCell.self, forCellReuseIdentifier: "HeaderCell")
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .darkGray
        
        // Setup search
        setupSearch()
        
        // Add long press gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPress)
    }
    
    private func setupSearch() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search headers..."
        search.hidesNavigationBarDuringPresentation = false
        
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        searchController = search
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        let header = filteredHeaders[indexPath.row]
        let text = "\(header.key): \(header.value)"
        
        UIPasteboard.general.string = text
        showCopyConfirmation()
    }
    
    private func showCopyConfirmation() {
        let alert = UIAlertController(title: nil, message: "Copied to clipboard", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredHeaders.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
        let header = filteredHeaders[indexPath.row]
        cell.configure(key: header.key, value: header.value, isJSON: header.isJSON, itemCount: header.itemCount)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let header = filteredHeaders[indexPath.row]
        guard header.isJSON else { return }
        
        // Open JSON browser
        guard let data = header.value.data(using: .utf8) else { return }
        let vc = BodyBrowserViewController(data: data, title: header.key, isRequest: false)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension HeadersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredHeaders = headers
            tableView.reloadData()
            return
        }
        
        let lowercasedSearch = searchText.lowercased()
        
        filteredHeaders = headers.filter { header in
            let keyMatches = header.key.lowercased().contains(lowercasedSearch)
            let valueMatches = header.value.lowercased().contains(lowercasedSearch)
            
            return keyMatches || valueMatches
        }
        
        tableView.reloadData()
    }
}

// MARK: - Header Cell

final class HeaderCell: UITableViewCell {
    private let keyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 3
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubview(keyLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            keyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            keyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            keyLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
            
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            keyLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.4)
        ])
    }
    
    func configure(key: String, value: String, isJSON: Bool, itemCount: Int) {
        keyLabel.text = key
        chevronImageView.isHidden = !isJSON
        
        if isJSON && itemCount > 0 {
            // Show count instead of value for JSON
            valueLabel.text = "\(itemCount) item\(itemCount == 1 ? "" : "s")"
        } else {
            valueLabel.text = value
        }
    }
}

