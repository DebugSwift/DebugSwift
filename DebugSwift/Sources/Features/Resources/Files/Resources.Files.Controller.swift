//
//  Resources.Files.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class ResourcesFilesViewController: BaseTableController {
    enum Constants {
        static let nextSizeAbbreviationThreshold: Double = 1024
    }
    
    enum ContainerType: CaseIterable {
        case appSandbox
        case appGroup
        
        var title: String {
            switch self {
            case .appSandbox:
                return "App Sandbox"
            case .appGroup:
                return "App Groups"
            }
        }
    }

    private var subdirectories = [String]()
    private var files = [String]()
    private var currentContainerType: ContainerType = .appSandbox
    private var appGroupIdentifiers: [String] = []

    private lazy var containerSegmentedControl: UISegmentedControl = {
        let items = ContainerType.allCases.map { $0.title }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(containerTypeChanged), for: .valueChanged)
        control.selectedSegmentTintColor = .systemBlue
        control.backgroundColor = .secondarySystemBackground
        return control
    }()

    private var pathLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .light)
        label.textColor = .darkGray
        label.numberOfLines = .zero
        return label
    }()

    private var filesTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .light)
        label.textColor = .darkGray
        label.numberOfLines = .zero
        label.text = "    Files"
        return label
    }()

    private let backgroundLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = .zero
        return label
    }()

    var path: String?
    var isRootLevel: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
        setupAppGroupIdentifiers()
        setupHeader()
        setupContents()
        setupViews()
        setupUI()
    }
    
    private func setupAppGroupIdentifiers() {
        // Use configured app group identifiers from DebugSwift.Resources
        appGroupIdentifiers = DebugSwift.Resources.shared.appGroupIdentifiers
        
        // If no identifiers are configured, try to detect from entitlements
        if appGroupIdentifiers.isEmpty {
            if let path = Bundle.main.path(forResource: "Entitlements", ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path),
               let appGroups = plist["com.apple.security.application-groups"] as? [String] {
                appGroupIdentifiers = appGroups
                // Auto-configure detected app groups for future use
                DebugSwift.Resources.shared.configureAppGroups(appGroups)
            }
        }
    }
    
    private func setupHeader() {
        if isRootLevel {
            let headerView = UIView()
            headerView.backgroundColor = .black
            
            headerView.addSubview(containerSegmentedControl)
            containerSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                containerSegmentedControl.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
                containerSegmentedControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                containerSegmentedControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
                containerSegmentedControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10),
                containerSegmentedControl.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            tableView.tableHeaderView = headerView
            headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
        }
    }
    
    @objc private func containerTypeChanged() {
        currentContainerType = ContainerType.allCases[containerSegmentedControl.selectedSegmentIndex]
        path = nil // Reset path when switching container types
        setupContents()
        tableView.reloadData()
    }

    private func setupContents() {
        refreshLabels()
        setupPaths()
        refreshLabels()
    }

    private func setupPaths() {
        var subdirectories = [String]()
        var files = [String]()
        
        let currentPath = getCurrentPath()
        
        do {
            let directoryContent = try FileManager.default.contentsOfDirectory(atPath: currentPath)
            for element in directoryContent {
                if element == "DebugSwift" {
                    continue
                }
                var isDirectory: ObjCBool = false
                let fullElementPath = (currentPath as NSString).appendingPathComponent(element)
                FileManager.default.fileExists(atPath: fullElementPath, isDirectory: &isDirectory)
                if isDirectory.boolValue {
                    subdirectories.append(element)
                } else {
                    files.append(element)
                }
            }
        } catch {
            Debug.print("Error reading directory: \(error)")
            
            // If we're trying to read app groups and failing, show available app group identifiers
            if currentContainerType == .appGroup && path == nil {
                subdirectories = appGroupIdentifiers.compactMap { identifier in
                    if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil {
                        return identifier
                    }
                    return nil
                }
            }
        }

        self.subdirectories = subdirectories.sorted()
        self.files = files.sorted()
    }
    
    private func getCurrentPath() -> String {
        switch currentContainerType {
        case .appSandbox:
            return path ?? NSHomeDirectory()
        case .appGroup:
            if let path = path {
                return path
            } else {
                // Show app group identifiers as "directories"
                return NSTemporaryDirectory() // Placeholder path
            }
        }
    }

    private func setupViews() {
        tableView.backgroundView = backgroundLabel
    }

    private func setupUI() {
        if title == nil {
            title = "Files"
        }
        view.backgroundColor = UIColor.black
    }

    private func refreshLabels() {
        let currentPath = getCurrentPath()
        let textPath: String
        
        switch currentContainerType {
        case .appSandbox:
            textPath = currentPath.replacingOccurrences(of: NSHomeDirectory(), with: "")
        case .appGroup:
            if let path = path {
                // Show relative path within app group
                textPath = path.replacingOccurrences(of: NSHomeDirectory(), with: "")
            } else {
                textPath = "App Groups"
            }
        }
        
        pathLabel.text = "    \(textPath.isEmpty ? "/" : textPath)"

        let totalItems = subdirectories.count + files.count
        backgroundLabel.text = totalItems > 0 ? "" : getEmptyStateMessage()
    }
    
    private func getEmptyStateMessage() -> String {
        switch currentContainerType {
        case .appSandbox:
            return "This directory is empty."
        case .appGroup:
            return path == nil ? "No accessible app groups found.\nCheck your app's entitlements." : "This app group directory is empty."
        }
    }
}

// MARK: - Table View Methods

extension ResourcesFilesViewController {
    override func numberOfSections(in _: UITableView) -> Int {
        2
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? subdirectories.count : files.count
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    override func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == .zero {
            return pathLabel
        }
        if !files.isEmpty {
            return filesTitle
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
            let directoryName = subdirectories[indexPath.row]
            
            // Special handling for app group identifiers at root level
            if currentContainerType == .appGroup && path == nil {
                cell.setup(
                    title: directoryName,
                    subtitle: "App Group Container",
                    image: .named("folder", default: "📁")
                )
            } else {
                cell.setup(title: directoryName)
            }

            return cell
        }
        let fileName = files[indexPath.row]
        let fileSize = sizeStringForFileWithName(fileName: fileName) ?? "No data"

        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        cell.setup(
            title: fileName,
            subtitle: "Size: \(fileSize)",
            image: .named("square.and.arrow.up", default: "Share")
        )

        return cell
    }

    override func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let fullPath = fullPathForElement(with: indexPath)
        return FileManager.default.isDeletableFile(atPath: fullPath)
    }

    override func tableView(
        _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let fullPath = fullPathForElement(with: indexPath)
            do {
                try FileManager.default.removeItem(atPath: fullPath)
                removeElementFromDataSource(with: indexPath)
                tableView.deleteRows(at: [indexPath], with: .fade)
                refreshLabels()
            } catch {
                presentAlertWithError(error)
            }
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == .zero {
            let subdirectoryName = subdirectories[indexPath.row]
            let filesTableViewController = ResourcesFilesViewController()
            
            if currentContainerType == .appGroup && path == nil {
                // Navigating into an app group container
                if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: subdirectoryName) {
                    filesTableViewController.path = containerURL.path
                    filesTableViewController.currentContainerType = .appGroup
                    filesTableViewController.isRootLevel = false
                } else {
                    showAlert(with: "Unable to access app group: \(subdirectoryName)")
                    return
                }
            } else {
                // Regular directory navigation
                filesTableViewController.path = (getCurrentPath() as NSString).appendingPathComponent(subdirectoryName)
                filesTableViewController.currentContainerType = currentContainerType
                filesTableViewController.isRootLevel = false
            }
            
            filesTableViewController.title = subdirectoryName
            navigationController?.pushViewController(filesTableViewController, animated: true)
        } else {
            let filePath = (getCurrentPath() as NSString).appendingPathComponent(files[indexPath.row])
            let fileURL = URL(fileURLWithPath: filePath)
            let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = tableView
                popover.permittedArrowDirections = .up
            }
            present(activity, animated: true, completion: nil)
        }
    }

    // MARK: - File size

    func sizeStringForFileWithName(fileName: String) -> String? {
        let fullPath = (getCurrentPath() as NSString).appendingPathComponent(fileName)
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: fullPath)[.size] as! UInt64
            let sizeUnitAbbreviations = ["B", "KB", "MB", "GB"]
            var fileSizeInBytes = Double(fileSize)
            for abbreviationIndex in 0..<sizeUnitAbbreviations.count {
                if fileSizeInBytes < Constants.nextSizeAbbreviationThreshold {
                    return String(format: "%.0f%@", fileSizeInBytes, sizeUnitAbbreviations[abbreviationIndex])
                }
                fileSizeInBytes /= Constants.nextSizeAbbreviationThreshold
            }
        } catch {
            Debug.print("Error getting file attributes: \(error)")
        }
        return nil
    }

    // MARK: - Element paths

    func fullPathForElement(with indexPath: IndexPath) -> String {
        let elementName = indexPath.section == 0 ? subdirectories[indexPath.row] : files[indexPath.row]
        return (getCurrentPath() as NSString).appendingPathComponent(elementName)
    }

    func removeElementFromDataSource(with indexPath: IndexPath) {
        _ = indexPath.section == 0 ? subdirectories.remove(at: indexPath.row) : files.remove(at: indexPath.row)
    }

    // MARK: - Alert

    func presentAlertWithError(_ error: Error) {
        let alert = UIAlertController(
            title: "Deletion error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let defaultAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil
        )
        alert.addAction(defaultAction)

        present(
            alert,
            animated: true,
            completion: nil
        )
    }
}
