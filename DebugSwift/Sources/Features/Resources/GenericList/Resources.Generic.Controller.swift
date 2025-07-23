//
//  Resources.Generic.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class ResourcesGenericController: BaseTableController {
    let viewModel: ResourcesGenericListViewModel
    var hideNavigationAddButton = false
    var onDataChanged: (() -> Void)?
    var onEditModeChanged: ((Bool) -> Void)?

    init(viewModel: ResourcesGenericListViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = UIColor.white
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
    
    private var selectedIndexPaths = Set<IndexPath>()
    private var isInEditMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.viewTitle()
        setupTableView()
        setupEmptyState()
        setupSearch()
        setupLongPressGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateNavigationButtons()
    }

    func setupTableView() {
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: .cell
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.black
        tableView.allowsMultipleSelectionDuringEditing = true

        updateNavigationButtons()

        viewModel.reloadData = { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        showActionSheet(for: indexPath)
    }
    
    private func showActionSheet(for indexPath: IndexPath) {
        let dataSource = viewModel.dataSourceForItem(atIndex: indexPath.row)
        
        let actionSheet = UIAlertController(title: dataSource.title, message: nil, preferredStyle: .actionSheet)
        
        if viewModel.isEditEnable {
            actionSheet.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
                self?.handleEditAction(at: indexPath.row)
            })
        }
        
        // Duplicate action
        actionSheet.addAction(UIAlertAction(title: "Duplicate", style: .default) { [weak self] _ in
            self?.handleDuplicateAction(at: indexPath.row)
        })
        
        if viewModel.isDeleteEnable {
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.showDeleteConfirmation(for: indexPath)
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        
        present(actionSheet, animated: true)
    }
    
    private func handleDuplicateAction(at index: Int) {
        let data = viewModel.dataSourceForItem(atIndex: index)
        
        // Generate unique key by appending a number
        var duplicateKey = "\(data.title)_copy"
        var counter = 1
        
        // Check if key already exists and increment counter
        while viewModel.keyExists(duplicateKey) {
            duplicateKey = "\(data.title)_copy_\(counter)"
            counter += 1
        }
        
        viewModel.addItem(key: duplicateKey, value: data.value)
        tableView.reloadData()
        updateNavigationButtons()
        onDataChanged?()
    }
    
    private func showDeleteConfirmation(for indexPath: IndexPath) {
        let dataSource = viewModel.dataSourceForItem(atIndex: indexPath.row)
        showAlert(
            with: "Delete Item",
            title: "Are you sure you want to delete '\(dataSource.title)'?",
            leftButtonTitle: "Delete",
            leftButtonStyle: .destructive,
            leftButtonHandler: { [weak self] _ in
                self?.viewModel.handleDeleteItemAction(atIndex: indexPath.row)
                self?.tableView.deleteRows(at: [indexPath], with: .fade)
                self?.updateNavigationButtons()
                
                // Exit edit mode if no items left
                if let self = self,
                   self.isInEditMode && self.viewModel.numberOfItems() == 0 {
                    self.toggleEditMode()
                }
                
                self?.onDataChanged?()
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }

    func setupSearch() {
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupEmptyState() {
        tableView.backgroundView = emptyStateLabel
    }
    
    private func updateNavigationButtons() {
        // If parent is handling buttons, don't show any navigation buttons
        if hideNavigationAddButton {
            navigationItem.rightBarButtonItems = []
            navigationItem.leftBarButtonItems = []
            return
        }
        
        if isInEditMode {
            updateEditModeButtons()
        } else {
            updateNormalModeButtons()
        }
    }
    
    private func updateNormalModeButtons() {
        var rightButtons = [UIBarButtonItem]()
        
        // Edit button - for multi-select mode (moved to right side)
        if viewModel.isDeleteEnable && viewModel.numberOfItems() > 0 {
            let editButton = UIBarButtonItem(
                title: "Edit",
                style: .plain,
                target: self,
                action: #selector(toggleEditMode)
            )
            rightButtons.append(editButton)
        }
        
        // Add button - always visible if enabled (unless hidden by parent)
        if viewModel.isAddEnable && !hideNavigationAddButton {
            let addButton = UIBarButtonItem(
                image: UIImage.named("plus.circle", default: "Add"),
                style: .plain,
                target: self,
                action: #selector(handleAddTapped)
            )
            addButton.tintColor = .systemBlue
            rightButtons.append(addButton)
        }
        
        // Share button
        if viewModel.isShareEnable && viewModel.numberOfItems() > 0 {
            let shareButton = UIBarButtonItem(
                image: UIImage.named("square.and.arrow.up", default: "Share"),
                style: .plain,
                target: self,
                action: #selector(handleShareTapped)
            )
            rightButtons.append(shareButton)
        }
        
        // Delete all button
        if viewModel.isDeleteEnable && viewModel.numberOfItems() > 0 {
            let deleteButton = UIBarButtonItem(
                image: UIImage.named("trash.circle", default: "Delete"),
                style: .plain,
                target: self,
                action: #selector(handleDeleteAllTapped)
            )
            deleteButton.tintColor = .red
            rightButtons.append(deleteButton)
        }
        
        navigationItem.rightBarButtonItems = rightButtons
        // Don't set left bar buttons to preserve the back button
        navigationItem.leftBarButtonItems = []
    }
    
    private func updateEditModeButtons() {
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(toggleEditMode)
        )
        
        let deleteButton = UIBarButtonItem(
            title: "Delete (\(selectedIndexPaths.count))",
            style: .plain,
            target: self,
            action: #selector(deleteSelectedItems)
        )
        deleteButton.tintColor = .red
        deleteButton.isEnabled = !selectedIndexPaths.isEmpty
        
        // Move both buttons to the right side to preserve back button
        navigationItem.rightBarButtonItems = [doneButton, deleteButton]
        navigationItem.leftBarButtonItems = []
    }
    
    @objc private func toggleEditMode() {
        isInEditMode.toggle()
        selectedIndexPaths.removeAll()
        
        tableView.setEditing(isInEditMode, animated: true)
        updateNavigationButtons()
        
        // Reload to update cell selection
        tableView.reloadData()
        
        // Notify parent controller
        onEditModeChanged?(isInEditMode)
    }
    
    @objc private func deleteSelectedItems() {
        guard !selectedIndexPaths.isEmpty else { return }
        
        let count = selectedIndexPaths.count
        let message = count == 1 ? "Are you sure you want to delete this item?" : "Are you sure you want to delete \(count) items?"
        
        showAlert(
            with: "Delete Items",
            title: message,
            leftButtonTitle: "Delete",
            leftButtonStyle: .destructive,
            leftButtonHandler: { [weak self] _ in
                self?.performBatchDelete()
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }
    
    private func performBatchDelete() {
        // Sort indices in descending order to avoid index shifting issues
        let sortedIndices = selectedIndexPaths
            .map { $0.row }
            .sorted(by: >)
        
        for index in sortedIndices {
            viewModel.handleDeleteItemAction(atIndex: index)
        }
        
        tableView.deleteRows(at: Array(selectedIndexPaths), with: .fade)
        
        selectedIndexPaths.removeAll()
        
        // Exit edit mode after deletion
        if viewModel.numberOfItems() == 0 || selectedIndexPaths.isEmpty {
            toggleEditMode()
        }
        
        updateNavigationButtons()
        onDataChanged?()
    }
    
    @objc private func handleAddTapped() {
        handleAddAction()
    }
    
    @objc private func handleShareTapped() {
        handleExportAction()
    }
    
    @objc private func handleDeleteAllTapped() {
        showAlert(
            with: "Warning",
            title: "This action will remove all data",
            leftButtonTitle: "Delete",
            leftButtonStyle: .destructive,
            leftButtonHandler: { [weak self] _ in
                self?.clearAction()
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }
    
    private func clearAction() {
        viewModel.handleClearAction()
        tableView.reloadData()
        updateNavigationButtons()
        onDataChanged?()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        let numberOfItems = viewModel.numberOfItems()

        if numberOfItems == .zero {
            emptyStateLabel.text = viewModel.emptyListDescriptionString()
            tableView.backgroundView = emptyStateLabel
        } else {
            tableView.backgroundView = nil
        }

        return numberOfItems
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)

        let dataSource = viewModel.dataSourceForItem(atIndex: indexPath.row)
        
        // Don't show action icons in edit mode
        if !isInEditMode {
            let image: UIImage? = viewModel.isEditEnable ? 
                .named("pencil.circle", default: "Edit") :
                viewModel.isCustomActionEnable ?
                .named("chevron.right.square", default: "Action") :
                .named("doc.on.doc", default: "Copy")
            cell.setup(
                title: dataSource.title,
                subtitle: dataSource.value,
                image: dataSource.actionImage ?? image
            )
        } else {
            cell.setup(
                title: dataSource.title,
                subtitle: dataSource.value,
                image: nil
            )
        }

        return cell
    }

    override func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        viewModel.isDeleteEnable && !isInEditMode
    }

    override func tableView(
        _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete, viewModel.isDeleteEnable {
            showDeleteConfirmation(for: indexPath)
        }
    }

    override func tableView(
        _: UITableView, titleForDeleteConfirmationButtonForRowAt _: IndexPath
    ) -> String? {
        viewModel.isDeleteEnable ? "Delete" : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isInEditMode {
            selectedIndexPaths.insert(indexPath)
            updateNavigationButtons()
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

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

        if viewModel.isEditEnable {
            handleEditAction(at: indexPath.row)
        } else if viewModel.isCustomActionEnable {
            viewModel.didTapItem(index: indexPath.row)
        } else {
            let title = cell.textLabel?.text ?? ""
            let contentToCopy = "\(title)"
            UIPasteboard.general.string = contentToCopy
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isInEditMode {
            selectedIndexPaths.remove(indexPath)
            updateNavigationButtons()
        }
    }

    // MARK: - Actions

    func triggerAddAction() {
        handleAddAction()
    }
    
    func triggerEditMode() {
        if viewModel.isDeleteEnable && viewModel.numberOfItems() > 0 {
            // Force toggle if not in edit mode, or exit if already in edit mode
            if !isInEditMode {
                toggleEditMode()
            } else {
                // Already in edit mode, so exit
                toggleEditMode()
            }
        }
    }
    
    func triggerExportAction() {
        if viewModel.isShareEnable && viewModel.numberOfItems() > 0 {
            handleExportAction()
        }
    }
    
    func triggerDeleteAllAction() {
        if viewModel.isDeleteEnable && viewModel.numberOfItems() > 0 {
            handleDeleteAllTapped()
        }
    }

    private func handleAddAction() {
        let editData = viewModel.getAddItemData()
        
        let editVC = ResourcesGenericEditViewController(
            keyPlaceholder: editData.keyPlaceholder,
            valuePlaceholder: editData.valuePlaceholder,
            title: editData.title
        )
        editVC.delegate = self
        
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }

    private func handleEditAction(at index: Int) {
        let editData = viewModel.getEditItemData(atIndex: index)
        
        let editVC = ResourcesGenericEditViewController(
            key: editData.key,
            value: editData.value,
            keyPlaceholder: editData.keyPlaceholder,
            valuePlaceholder: editData.valuePlaceholder,
            title: editData.title
        )
        editVC.delegate = self
        self.editingIndex = index
        
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }

    private func handleExportAction() {
        let exportData = viewModel.exportData()
        
        // Create a temporary file
        let fileName = "\(viewModel.viewTitle())_\(Date().timeIntervalSince1970).json"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)
        
        do {
            try exportData.write(to: fileURL)
            
            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Set up the completion handler to clean up the temporary file
            activityViewController.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = navigationController?.navigationBar
                popover.sourceRect = CGRect(
                    x: (navigationController?.navigationBar.bounds.width ?? 0) - 50,
                    y: (navigationController?.navigationBar.bounds.height ?? 0) / 2,
                    width: 0,
                    height: 0
                )
            }
            
            present(activityViewController, animated: true)
        } catch {
            showAlert(with: "Export Error", title: "Failed to export data: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Properties
    
    private var editingIndex: Int?
}

// MARK: - ResourcesGenericEditDelegate
extension ResourcesGenericController: ResourcesGenericEditDelegate {
    func didSaveItem(key: String, value: String, originalKey: String?) {
        if let index = editingIndex {
            viewModel.updateItem(atIndex: index, key: key, value: value)
            editingIndex = nil
        } else {
            viewModel.addItem(key: key, value: value)
        }
        tableView.reloadData()
        updateNavigationButtons()
        onDataChanged?()
    }
}

extension ResourcesGenericController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        viewModel.filterContentForSearchText(searchText)
        viewModel.isSearchActived = !searchText.isEmpty
        tableView.reloadData()
    }
}

protocol ResourcesGenericListViewModel: AnyObject {
    typealias ViewData = ResourcesGenericController.CellViewData

    var isSearchActived: Bool { get set }

    var isDeleteEnable: Bool { get }

    var isShareEnable: Bool { get }

    var isCustomActionEnable: Bool { get }

    var isEditEnable: Bool { get }

    var isAddEnable: Bool { get }

    var reloadData: (() -> Void)? { get set }

    /// Returns the number of title-value pairs.
    func numberOfItems() -> Int

    /// Returns a `String` instance that will be used as a title for `Controller` instance.
    func viewTitle() -> String

    /// Provides the data source object for a cell at the given index.
    /// - Parameter index: The index of the cell that needs the data source.
    func dataSourceForItem(atIndex index: Int) -> ViewData

    /// Handles tap on the clear button on the navigation bar.
    func handleClearAction()

    /// Handles tap on the share button on the navigation bar.
    func handleShareAction()

    /// Returns data for adding a new item.
    func getAddItemData() -> ResourcesGenericController.EditItemData

    /// Returns data for editing an existing item.
    func getEditItemData(atIndex index: Int) -> ResourcesGenericController.EditItemData

    /// Updates an existing item.
    func updateItem(atIndex index: Int, key: String, value: String)

    /// Adds a new item.
    func addItem(key: String, value: String)

    /// Handles delete action on the cell at the given index.
    /// - Parameter index: The index of the cell that the user chose to delete.
    func handleDeleteItemAction(atIndex index: Int)

    /// Returns a `String` instance that will be used as text in the background label of the table view.
    func emptyListDescriptionString() -> String

    /// Filters the content based on the search text.
    /// - Parameter searchText: The text to be used for filtering.
    func filterContentForSearchText(_ searchText: String)

    func didTapItem(index: Int)

    /// Exports data for sharing.
    func exportData() -> Data
    
    /// Checks if a key already exists
    func keyExists(_ key: String) -> Bool
}

// Optional

extension ResourcesGenericListViewModel {
    var isDeleteEnable: Bool { true }
    var isShareEnable: Bool { true }

    var isCustomActionEnable: Bool { false }

    var isEditEnable: Bool { false }

    var isAddEnable: Bool { false }

    func didTapItem(index _: Int) {}

    func handleClearAction() {}
    func handleShareAction() {}

    func getAddItemData() -> ResourcesGenericController.EditItemData { ResourcesGenericController.EditItemData(key: nil, value: nil, keyPlaceholder: "Key", valuePlaceholder: "Value", title: "Add Item") }

    func getEditItemData(atIndex _: Int) -> ResourcesGenericController.EditItemData { ResourcesGenericController.EditItemData(key: "", value: "", keyPlaceholder: "Key", valuePlaceholder: "Value", title: "Edit Item") }

    func updateItem(atIndex _: Int, key _: String, value _: String) {}

    func addItem(key _: String, value _: String) {}

    func handleDeleteItemAction(atIndex _: Int) {}

    func exportData() -> Data { Data() }
    
    func keyExists(_ key: String) -> Bool { false }
}

extension ResourcesGenericController {
    struct CellViewData {
        let title: String
        let value: String
        let actionImage: UIImage?

        init(
            title: String,
            value: String = "",
            actionImage: UIImage? = nil
        ) {
            self.title = title
            self.value = value
            self.actionImage = actionImage
        }
    }
    
    struct EditItemData {
        let key: String?
        let value: String?
        let keyPlaceholder: String
        let valuePlaceholder: String
        let title: String
    }
}
