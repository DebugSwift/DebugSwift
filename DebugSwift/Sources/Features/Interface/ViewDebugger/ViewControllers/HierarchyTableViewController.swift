//
//  HierarchyTableViewController.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/6/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

@MainActor
protocol HierarchyTableViewControllerDelegate: AnyObject {
    func hierarchyTableViewController(_ viewController: HierarchyTableViewController, didSelectSnapshot snapshot: Snapshot)
    func hierarchyTableViewController(_ viewController: HierarchyTableViewController, didDeselectSnapshot snapshot: Snapshot)
    func hierarchyTableViewController(_ viewController: HierarchyTableViewController, didFocusOnSnapshot snapshot: Snapshot)
    func hierarchyTableViewControllerWillNavigateBackToPreviousSnapshot(_ viewController: HierarchyTableViewController)
}

final class HierarchyTableViewController: UITableViewController, HierarchyTableViewCellDelegate, HierarchyTableViewControllerDelegate {
    private static let ReuseIdentifier = "HierarchyTableViewCell"

    private let snapshot: Snapshot
    private let configuration: HierarchyViewConfiguration
    
    private var expandableDataSource: ExpandableTreeDataSource<Snapshot>?

    weak var delegate: HierarchyTableViewControllerDelegate?

    init(snapshot: Snapshot, configuration: HierarchyViewConfiguration) {
        self.snapshot = snapshot
        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = snapshot.element.label.name
        clearsSelectionOnViewWillAppear = false

        self.expandableDataSource = ExpandableTreeDataSource(
            tree: snapshot,
            cellFactory: cellFactory()
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(HierarchyTableViewCell.self, forCellReuseIdentifier: HierarchyTableViewController.ReuseIdentifier)
        tableView.dataSource = expandableDataSource
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            deselectAll()
            delegate?.hierarchyTableViewControllerWillNavigateBackToPreviousSnapshot(self)
        }
    }

    // MARK: API

    func selectRow(forSnapshot snapshot: Snapshot) {
        let indexPath = expandableDataSource?.indexPath(forValue: snapshot)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
    }

    func deselectRow(forSnapshot snapshot: Snapshot) {
        guard let indexPath = expandableDataSource?.indexPath(forValue: snapshot) else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func focus(snapshot: Snapshot) {
        // For expandable tree, just expand the node
        guard let dataSource = expandableDataSource else { return }
        
        if !dataSource.isExpanded(snapshot) {
            let changes = dataSource.toggleExpansion(snapshot)
            tableView.beginUpdates()
            if changes.count > 1 {
                tableView.reloadRows(at: changes, with: .automatic)
            } else {
                tableView.reloadData()
            }
            tableView.endUpdates()
        }
        
        if let indexPath = dataSource.indexPath(forValue: snapshot) {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let snapshot = expandableDataSource?.value(atIndexPath: indexPath) else {
            return
        }
        delegate?.hierarchyTableViewController(self, didSelectSnapshot: snapshot)
    }

    override func tableView(_: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let snapshot = expandableDataSource?.value(atIndexPath: indexPath) else {
            return
        }
        delegate?.hierarchyTableViewController(self, didDeselectSnapshot: snapshot)
    }

    // MARK: HierarchyTableViewCellDelegate

    func hierarchyTableViewCellDidTap(cell: HierarchyTableViewCell) {
        guard let indexPath = cell.indexPath, 
              let snapshot = expandableDataSource?.value(atIndexPath: indexPath) else {
            return
        }
        
        if !snapshot.children.isEmpty {
            let changes = expandableDataSource?.toggleExpansion(snapshot) ?? []
            
            tableView.beginUpdates()
            if changes.count > 1 {
                tableView.reloadRows(at: changes, with: .automatic)
            } else {
                tableView.reloadData()
            }
            tableView.endUpdates()
        }
    }

    func hierarchyTableViewCellDidLongPress(cell: HierarchyTableViewCell, point: CGPoint) {
        guard let indexPath = cell.indexPath, 
              let snapshot = expandableDataSource?.value(atIndexPath: indexPath) else {
            return
        }
        let actionSheet = actionSheet(for: snapshot, from: cell, at: point) {
            self.focus(snapshot: snapshot)
        }
        present(actionSheet, animated: true, completion: nil)
    }

    // MARK: HierarchyTableViewControllerDelegate

    func hierarchyTableViewController(_: HierarchyTableViewController, didSelectSnapshot snapshot: Snapshot) {
        delegate?.hierarchyTableViewController(self, didSelectSnapshot: snapshot)
    }

    func hierarchyTableViewController(_: HierarchyTableViewController, didDeselectSnapshot snapshot: Snapshot) {
        delegate?.hierarchyTableViewController(self, didDeselectSnapshot: snapshot)
    }

    func hierarchyTableViewController(_: HierarchyTableViewController, didFocusOnSnapshot snapshot: Snapshot) {
        delegate?.hierarchyTableViewController(self, didFocusOnSnapshot: snapshot)
    }

    func hierarchyTableViewControllerWillNavigateBackToPreviousSnapshot(_: HierarchyTableViewController) {
        delegate?.hierarchyTableViewControllerWillNavigateBackToPreviousSnapshot(self)
    }

    // MARK: Private

    private func deselectAll() {
        guard let indexPaths = tableView?.indexPathsForSelectedRows else {
            return
        }
        for indexPath in indexPaths {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    private func cellFactory() -> ExpandableTreeDataSource<Snapshot>.CellFactory {
        { [unowned self] tableView, value, depth, indexPath, isExpanded in
            let reuseIdentifier = HierarchyTableViewController.ReuseIdentifier
            let cell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? HierarchyTableViewCell) ?? HierarchyTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)

            configureCellAppearance(cell: cell, value: value, depth: depth, indexPath: indexPath, isExpanded: isExpanded)
            return cell
        }
    }
    
    private func configureCellAppearance(cell: HierarchyTableViewCell, value: Snapshot, depth: Int, indexPath: IndexPath, isExpanded: Bool) {
        let baseFont = configuration.nameFont
        switch value.label.classification {
        case .normal:
            cell.nameLabel.font = baseFont
        case .important:
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits(.traitBold) {
                cell.nameLabel.font = UIFont(descriptor: descriptor, size: baseFont.pointSize)
            } else {
                cell.nameLabel.font = baseFont
            }
        }
        cell.nameLabel.text = value.label.name

        let frame = value.frame
        cell.frameLabel.font = configuration.frameFont
        cell.frameLabel.text = String(format: "(%.1f, %.1f, %.1f, %.1f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
        cell.lineView.lineCount = depth
        cell.lineView.lineColors = configuration.lineColors
        cell.lineView.lineWidth = configuration.lineWidth
        cell.lineView.lineSpacing = configuration.lineSpacing
        cell.hasChildren = !value.children.isEmpty
        cell.isExpanded = isExpanded
        cell.indexPath = indexPath
        cell.delegate = self
    }
}

extension Snapshot: Tree {}
