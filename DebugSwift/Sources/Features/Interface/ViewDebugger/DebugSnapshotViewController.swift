//
//  DebugSnapshotViewController.swift
//  LiveSnapshot
//
//  Created by Indragie Karunaratne on 3/30/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

protocol DebugSnapshotViewControllerDelegate: AnyObject {
    func debugSnapshotViewController(_ viewController: DebugSnapshotViewController, didSelectSnapshot snapshot: Snapshot)
    func debugSnapshotViewController(_ viewController: DebugSnapshotViewController, didDeselectSnapshot snapshot: Snapshot)
    func debugSnapshotViewController(_ viewController: DebugSnapshotViewController, didFocusOnSnapshot snapshot: Snapshot)
    func debugSnapshotViewControllerWillNavigateBackToPreviousSnapshot(_ viewController: DebugSnapshotViewController)
}

/// View controller that renders a 3D snapshot view using SceneKit.
final class DebugSnapshotViewController: UIViewController, SnapshotViewDelegate, DebugSnapshotViewControllerDelegate {
    private let snapshot: Snapshot
    private let configuration: SnapshotViewConfiguration
    
    private var snapshotView: SnapshotView?
    weak var delegate: DebugSnapshotViewControllerDelegate?
    
    init(
        snapshot: Snapshot,
        configuration: SnapshotViewConfiguration = SnapshotViewConfiguration(),
        delegate: DebugSnapshotViewControllerDelegate?
    ) {
        self.snapshot = snapshot
        self.configuration = configuration
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
        
        navigationItem.title = snapshot.element.label.name
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func loadView() {
        let snapshotView = SnapshotView(snapshot: snapshot, configuration: configuration)
        snapshotView.delegate = self
        self.snapshotView = snapshotView
        self.view = snapshotView
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            snapshotView?.deselectAll()
            delegate?.debugSnapshotViewControllerWillNavigateBackToPreviousSnapshot(self)
        }
    }
    
    // MARK: API
    
    func select(snapshot: Snapshot) {
        let topViewController = topDebugSnapshotViewController()
        if topViewController == self {
            snapshotView?.select(snapshot: snapshot)
        } else {
            topViewController.select(snapshot: snapshot)
        }
    }
    
    func deselect(snapshot: Snapshot) {
        let topViewController = topDebugSnapshotViewController()
        if topViewController == self {
            snapshotView?.deselect(snapshot: snapshot)
        } else {
            topViewController.deselect(snapshot: snapshot)
        }
    }
    
    func focus(snapshot: Snapshot) {
        focus(snapshot: snapshot, callDelegate: false)
    }
    
    // MARK: SnapshotViewDelegate
    
    func snapshotView(_ snapshotView: SnapshotView, didSelectSnapshot snapshot: Snapshot) {
        delegate?.debugSnapshotViewController(self, didSelectSnapshot: snapshot)
    }
    
    func snapshotView(_ snapshotView: SnapshotView, didDeselectSnapshot snapshot: Snapshot) {
        delegate?.debugSnapshotViewController(self, didDeselectSnapshot: snapshot)
    }

    func snapshotView(_ snapshotView: SnapshotView, didLongPressSnapshot snapshot: Snapshot, point: CGPoint) {
        let actionSheet = makeActionSheet(snapshot: snapshot, sourceView: snapshotView, sourcePoint: point) { snapshot in
            self.focus(snapshot: snapshot, callDelegate: true)
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    func snapshotView(_ snapshotView: SnapshotView, showAlertController alertController: UIAlertController) {
        present(alertController, animated: true, completion: nil)
    }

    // MARK: DebugSnapshotViewControllerDelegate
    
    func debugSnapshotViewController(_ viewController: DebugSnapshotViewController, didSelectSnapshot snapshot: Snapshot) {
        delegate?.debugSnapshotViewController(self, didSelectSnapshot: snapshot)
    }
    
    func debugSnapshotViewController(_ viewController: DebugSnapshotViewController, didDeselectSnapshot snapshot: Snapshot) {
        delegate?.debugSnapshotViewController(self, didDeselectSnapshot: snapshot)
    }
    
    func debugSnapshotViewController(_ viewController: DebugSnapshotViewController, didFocusOnSnapshot snapshot: Snapshot) {
        delegate?.debugSnapshotViewController(self, didFocusOnSnapshot: snapshot)
    }
    
    func debugSnapshotViewControllerWillNavigateBackToPreviousSnapshot(_ viewController: DebugSnapshotViewController) {
        delegate?.debugSnapshotViewControllerWillNavigateBackToPreviousSnapshot(self)
    }
    
    // MARK: Private
    
    private func focus(snapshot: Snapshot, callDelegate: Bool) {
        let topViewController = topDebugSnapshotViewController()
        if topViewController == self {
            snapshotView?.deselectAll()
            let subtreeViewController = Self(
                snapshot: snapshot,
                configuration: configuration,
                delegate: self
            )
            navigationController?.pushViewController(subtreeViewController, animated: true)
            if callDelegate {
                delegate?.debugSnapshotViewController(self, didFocusOnSnapshot: snapshot)
            }
        } else {
            topViewController.focus(snapshot: snapshot)
        }
    }
    
    private func topDebugSnapshotViewController() -> DebugSnapshotViewController {
        if let DebugSnapshotViewController = navigationController?.topViewController as? DebugSnapshotViewController {
            return DebugSnapshotViewController
        }
        return self
    }
}
