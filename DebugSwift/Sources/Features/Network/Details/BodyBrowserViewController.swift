//
//  BodyBrowserViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 14/01/26.
//

import UIKit

final class BodyBrowserViewController: BaseTableController {
    private let data: Data?
    private let bodyTitle: String
    private let isRequest: Bool
    
    private var items: [(key: String, value: String)] = []
    private var isStructuredData = false
    private var searchController: UISearchController?
    private var filteredItems: [(key: String, value: String)] = []
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .black
        textView.textColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        return textView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    init(data: Data?, title: String, isRequest: Bool) {
        self.data = data
        self.bodyTitle = title
        self.isRequest = isRequest
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadContent()
    }
    
    private func setupUI() {
        title = bodyTitle
        view.backgroundColor = .black
        
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add copy button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(showCopyOptions)
        )
    }
    
    private func loadContent() {
        guard let data = data else {
            showTextView(with: "No data")
            return
        }
        
        // For large data, load asynchronously
        if data.count > 100_000 {
            loadingIndicator.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                Task { @MainActor [weak self] in
                    self?.parseData(data)
                }
            }
        } else {
            parseData(data)
        }
    }
    
    private func parseData(_ data: Data) {
        // Try to parse as JSON
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
            if let dictionary = jsonObject as? [String: Any] {
                let items = flattenJSON(dictionary: dictionary)
                DispatchQueue.main.async { [weak self] in
                    self?.showStructuredData(items: items)
                }
                return
            } else if let array = jsonObject as? [Any] {
                let items = flattenJSONArray(array: array)
                DispatchQueue.main.async { [weak self] in
                    self?.showStructuredData(items: items)
                }
                return
            }
        }
        
        // Try to parse as form data
        if let formData = parseFormData(data) {
            DispatchQueue.main.async { [weak self] in
                self?.showStructuredData(items: formData)
            }
            return
        }
        
        // Fallback to plain text
        let formatted = data.formattedString()
        DispatchQueue.main.async { [weak self] in
            self?.showTextView(with: formatted)
        }
    }
    
    private func flattenJSON(dictionary: [String: Any], prefix: String = "") -> [(key: String, value: String)] {
        var result: [(key: String, value: String)] = []
        
        let sortedKeys = dictionary.keys.sorted()
        for key in sortedKeys {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            let value = dictionary[key]
            
            if let dict = value as? [String: Any] {
                result.append(contentsOf: flattenJSON(dictionary: dict, prefix: fullKey))
            } else if let array = value as? [Any] {
                result.append(contentsOf: flattenJSONArray(array: array, prefix: fullKey))
            } else if let value = value {
                result.append((key: fullKey, value: "\(value)"))
            } else {
                result.append((key: fullKey, value: "null"))
            }
        }
        
        return result
    }
    
    private func flattenJSONArray(array: [Any], prefix: String = "") -> [(key: String, value: String)] {
        var result: [(key: String, value: String)] = []
        
        for (index, item) in array.enumerated() {
            let fullKey = prefix.isEmpty ? "[\(index)]" : "\(prefix)[\(index)]"
            
            if let dict = item as? [String: Any] {
                result.append(contentsOf: flattenJSON(dictionary: dict, prefix: fullKey))
            } else if let nestedArray = item as? [Any] {
                result.append(contentsOf: flattenJSONArray(array: nestedArray, prefix: fullKey))
            } else {
                result.append((key: fullKey, value: "\(item)"))
            }
        }
        
        return result
    }
    
    private func parseFormData(_ data: Data) -> [(key: String, value: String)]? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        
        // Check if it's URL-encoded form data
        let pairs = string.components(separatedBy: "&")
        guard pairs.count > 0 else { return nil }
        
        var result: [(key: String, value: String)] = []
        for pair in pairs {
            let components = pair.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0].removingPercentEncoding ?? components[0]
                let value = components[1].removingPercentEncoding ?? components[1]
                result.append((key: key, value: value))
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    private func showStructuredData(items: [(key: String, value: String)]) {
        self.items = items
        self.filteredItems = items
        self.isStructuredData = true
        
        loadingIndicator.stopAnimating()
        
        // Setup table view
        tableView.register(BodyKeyValueCell.self, forCellReuseIdentifier: "BodyKeyValueCell")
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .darkGray
        tableView.reloadData()
        
        // Always setup search for better UX
        setupSearch()
        
        // Add long press gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPress)
    }
    
    private func showTextView(with text: String) {
        self.isStructuredData = false
        
        loadingIndicator.stopAnimating()
        
        // Remove table view and show text view
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        textView.text = text
        
        // Add long press gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressTextView))
        textView.addGestureRecognizer(longPress)
    }
    
    private func setupSearch() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search keys and values..."
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
        
        let item = filteredItems[indexPath.row]
        let text = "\(item.key): \(item.value)"
        
        UIPasteboard.general.string = text
        showCopyConfirmation()
    }
    
    @objc private func handleLongPressTextView(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        // If there's a text selection, copy that. Otherwise copy all
        if let selectedRange = textView.selectedTextRange,
           !selectedRange.isEmpty,
           let selectedText = textView.text(in: selectedRange) {
            UIPasteboard.general.string = selectedText
        } else {
            UIPasteboard.general.string = textView.text
        }
        
        showCopyConfirmation()
    }
    
    @objc private func showCopyOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Copy Body", style: .default) { [weak self] _ in
            self?.copyBodyContent()
        })
        
        alert.addAction(UIAlertAction(title: "Copy JSON Body", style: .default) { [weak self] _ in
            self?.copyJSONBody()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func copyBodyContent() {
        if isStructuredData {
            let text = items.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            UIPasteboard.general.string = text
        } else {
            UIPasteboard.general.string = textView.text
        }
        showCopyConfirmation()
    }
    
    private func copyJSONBody() {
        UIPasteboard.general.string = data?.formattedString() ?? "No data"
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
        guard isStructuredData else { return 0 }
        return filteredItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BodyKeyValueCell", for: indexPath) as! BodyKeyValueCell
        let item = filteredItems[indexPath.row]
        cell.configure(key: item.key, value: item.value)
        return cell
    }
}

// MARK: - UISearchResultsUpdating

extension BodyBrowserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredItems = items
            tableView.reloadData()
            return
        }
        
        // Deep search through keys and values
        // Search in full key path and values
        let lowercasedSearch = searchText.lowercased()
        
        filteredItems = items.filter { item in
            let keyMatches = item.key.lowercased().contains(lowercasedSearch)
            let valueMatches = item.value.lowercased().contains(lowercasedSearch)
            
            // Also search in individual key components (e.g., "name" matches "user.profile.name")
            let keyComponents = item.key.components(separatedBy: CharacterSet(charactersIn: ".[]"))
            let keyComponentMatches = keyComponents.contains { component in
                !component.isEmpty && component.lowercased().contains(lowercasedSearch)
            }
            
            return keyMatches || valueMatches || keyComponentMatches
        }
        
        tableView.reloadData()
    }
}

// MARK: - Body Key-Value Cell

final class BodyKeyValueCell: UITableViewCell {
    private let keyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
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
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none
        
        let stackView = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            keyLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.35)
        ])
    }
    
    func configure(key: String, value: String) {
        keyLabel.text = key
        valueLabel.text = value
    }
}
