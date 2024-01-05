//
//  HierarchyTableViewController.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/6/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

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
    
    private var dataSource: TreeTableViewDataSource<Snapshot>? {
        didSet {
            if isViewLoaded {
                tableView?.dataSource = dataSource
                tableView?.reloadData()
            }
        }
    }
    
    private var shouldIgnoreMaxDepth = false {
        didSet {
            if shouldIgnoreMaxDepth != oldValue {
                dataSource = TreeTableViewDataSource(
                    tree: snapshot,
                    maxDepth: shouldIgnoreMaxDepth ? nil : configuration.maxDepth?.intValue,
                    cellFactory: cellFactory(shouldIgnoreMaxDepth: shouldIgnoreMaxDepth)
                )
            }
        }
    }
    
    weak var delegate: HierarchyTableViewControllerDelegate?
    
    init(snapshot: Snapshot, configuration: HierarchyViewConfiguration) {
        self.snapshot = snapshot
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
        
        navigationItem.title = snapshot.element.label.name
        clearsSelectionOnViewWillAppear = false
        
        self.dataSource = TreeTableViewDataSource(
            tree: snapshot,
            maxDepth: configuration.maxDepth?.intValue,
            cellFactory: cellFactory(shouldIgnoreMaxDepth: false)
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(HierarchyTableViewCell.self, forCellReuseIdentifier: HierarchyTableViewController.ReuseIdentifier)
        tableView.dataSource = dataSource
        tableView.separatorStyle = .none
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
        let topViewController = topHierarchyViewController()
        if topViewController == self {
            shouldIgnoreMaxDepth = true
            let indexPath = dataSource?.indexPath(forValue: snapshot)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        } else {
            topViewController.selectRow(forSnapshot: snapshot)
        }
    }
    
    func deselectRow(forSnapshot snapshot: Snapshot) {
        let topViewController = topHierarchyViewController()
        if topViewController == self {
            shouldIgnoreMaxDepth = false
            guard let indexPath = dataSource?.indexPath(forValue: snapshot) else {
                return
            }
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            topViewController.deselectRow(forSnapshot: snapshot)
        }
    }
    
    func focus(snapshot: Snapshot) {
        focus(snapshot: snapshot, callDelegate: false)
    }
    
    private func focus(snapshot: Snapshot, callDelegate: Bool) {
        let topViewController = topHierarchyViewController()
        if topViewController == self {
            pushSubtreeViewController(snapshot: snapshot, callDelegate: callDelegate)
        } else {
            topViewController.focus(snapshot: snapshot)
        }

    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let snapshot = dataSource?.value(atIndexPath: indexPath) else {
            return
        }
        delegate?.hierarchyTableViewController(self, didSelectSnapshot: snapshot)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let snapshot = dataSource?.value(atIndexPath: indexPath) else {
            return
        }
        delegate?.hierarchyTableViewController(self, didDeselectSnapshot: snapshot)
    }
    
    // MARK: HierarchyTableViewCellDelegate
    
    func hierarchyTableViewCellDidTapSubtree(cell: HierarchyTableViewCell) {
        guard let indexPath = cell.indexPath, let snapshot = dataSource?.value(atIndexPath: indexPath) else {
            return
        }
        pushSubtreeViewController(snapshot: snapshot, callDelegate: true)
    }
    
    func hierarchyTableViewCellDidLongPress(cell: HierarchyTableViewCell, point: CGPoint) {
        guard let indexPath = cell.indexPath, let snapshot = dataSource?.value(atIndexPath: indexPath) else {
            return
        }
        let actionSheet = makeActionSheet(snapshot: snapshot, sourceView: cell, sourcePoint: point) { snapshot in
            self.focus(snapshot: snapshot, callDelegate: true)
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: HierarchyTableViewControllerDelegate
    
    func hierarchyTableViewController(_ viewController: HierarchyTableViewController, didSelectSnapshot snapshot: Snapshot) {
        delegate?.hierarchyTableViewController(self, didSelectSnapshot: snapshot)
    }
    
    func hierarchyTableViewController(_ viewController: HierarchyTableViewController, didDeselectSnapshot snapshot: Snapshot) {
        delegate?.hierarchyTableViewController(self, didDeselectSnapshot: snapshot)
    }
    
    func hierarchyTableViewController(_ viewController: HierarchyTableViewController, didFocusOnSnapshot snapshot: Snapshot) {
        delegate?.hierarchyTableViewController(self, didFocusOnSnapshot: snapshot)
    }
    
    func hierarchyTableViewControllerWillNavigateBackToPreviousSnapshot(_ viewController: HierarchyTableViewController) {
        delegate?.hierarchyTableViewControllerWillNavigateBackToPreviousSnapshot(self)
    }
    
    // MARK: Private
    
    private func pushSubtreeViewController(snapshot: Snapshot, callDelegate: Bool) {
        deselectAll()
        let subtreeViewController = HierarchyTableViewController(snapshot: snapshot, configuration: configuration)
        subtreeViewController.delegate = self
        navigationController?.pushViewController(subtreeViewController, animated: true)
        if callDelegate {
            delegate?.hierarchyTableViewController(self, didFocusOnSnapshot: snapshot)
        }
    }
    
    private func deselectAll() {
        guard let indexPaths = tableView?.indexPathsForSelectedRows else {
            return
        }
        for indexPath in indexPaths {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    private func topHierarchyViewController() -> HierarchyTableViewController {
        if let hierarchyViewController = navigationController?.topViewController as? HierarchyTableViewController {
            return hierarchyViewController
        }
        return self
    }
    
    private func cellFactory(shouldIgnoreMaxDepth: Bool) -> TreeTableViewDataSource<Snapshot>.CellFactory {
        return { [unowned self] (tableView, value, depth, indexPath, isCollapsed) in
            let reuseIdentifier = HierarchyTableViewController.ReuseIdentifier
            let cell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? HierarchyTableViewCell) ?? HierarchyTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
            
            let baseFont = self.configuration.nameFont
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
            cell.frameLabel.font = self.configuration.frameFont
            cell.frameLabel.text = String(format: "(%.1f, %.1f, %.1f, %.1f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
            cell.lineView.lineCount = depth
            cell.lineView.lineColors = self.configuration.lineColors
            cell.lineView.lineWidth = self.configuration.lineWidth
            cell.lineView.lineSpacing = self.configuration.lineSpacing
            cell.showSubtreeButton = !shouldIgnoreMaxDepth && !value.children.isEmpty && depth >= (self.configuration.maxDepth?.intValue ?? Int.max)
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        }
    }
}

extension Snapshot: Tree {}
