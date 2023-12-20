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

    private var subdirectories = [String]()
    private var files = [String]()

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
        label.text = "files".localized()
        return label
    }()

    private let backgroundLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = .zero
        return label
    }()

    var path: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
        setupContents()
        setupViews()
        setupUI()
    }

    private func setupContents() {
        refreshLabels()
        setupPaths()
        refreshLabels()
    }

    private func setupPaths() {
        var subdirectories = [String]()
        var files = [String]()
        do {
            let directoryContent = try FileManager.default.contentsOfDirectory(atPath: path!)
            for element in directoryContent {
                if element == "DebugSwift" {
                    continue
                }
                var isDirectory: ObjCBool = false
                let fullElementPath = (path! as NSString).appendingPathComponent(element)
                FileManager.default.fileExists(atPath: fullElementPath, isDirectory: &isDirectory)
                if isDirectory.boolValue {
                    subdirectories.append(element)
                } else {
                    files.append(element)
                }
            }
        } catch {
            Debug.print("Error reading directory: \(error)")
        }

        self.subdirectories = subdirectories.sorted()
        self.files = files.sorted()
    }

    private func setupViews() {
        tableView.backgroundView = backgroundLabel
    }

    private func setupUI() {
        if title == nil {
            title = "files-title".localized()
        }
        view.backgroundColor = .black
    }

    private func refreshLabels() {
        let textPath = path?.replacingOccurrences(of: NSHomeDirectory(), with: "") ?? "/"
        pathLabel.text = "    \(textPath.isEmpty ? "/" : textPath)"
        if path == nil { path = NSHomeDirectory() }

        backgroundLabel.text =
        (subdirectories.count + files.count > 0) ? "" : "empty-directory".localized()
    }
}

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
        } else if !files.isEmpty {
            return filesTitle
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
            cell.setup(title: subdirectories[indexPath.row])

            return cell
        } else {
            let fileName = files[indexPath.row]
            let fileSize = sizeStringForFileWithName(fileName: fileName) ?? "No data"

            let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
            cell.setup(
                title: fileName,
                subtitle: "Size: \(fileSize)",
                image: .init(named: "square.and.arrow.up")
            )

            return cell
        }
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
            filesTableViewController.path = (path! as NSString).appendingPathComponent(subdirectoryName)
            filesTableViewController.title = subdirectoryName

            navigationController?.pushViewController(filesTableViewController, animated: true)
        } else {
            let filePath = (path! as NSString).appendingPathComponent(files[indexPath.row])
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
        let fullPath = (path! as NSString).appendingPathComponent(fileName)
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
        return (path! as NSString).appendingPathComponent(elementName)
    }

    func removeElementFromDataSource(with indexPath: IndexPath) {
        var affectedArray = indexPath.section == 0 ? subdirectories : files
        affectedArray.remove(at: indexPath.row)
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
