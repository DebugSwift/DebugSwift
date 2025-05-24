//
//  InAppViewDebugger.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/4/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

/// Exposes APIs for presenting the view debugger.
@MainActor
final class InAppViewDebugger: NSObject {
    /// Takes a snapshot of the application's key window and presents the debugger
    /// view controller from the root view controller.
    final class func present() {
        presentForWindow(UIApplication.keyWindow)
    }

    /// Takes a snapshot of the specified window and presents the debugger view controller
    /// from the root view controller.
    ///
    /// - Parameters:
    ///   - window: The view controller whose view should be snapshotted.
    ///   - configuration: Optional configuration for the view debugger.
    ///   - completion: Completion block to be called once the view debugger has
    ///   been presented.
    final class func presentForWindow(
        _ window: UIWindow?,
        configuration: Configuration? = nil,
        completion: (() -> Void)? = nil
    ) {
        guard let window else {
            return
        }

        let snapshot = Snapshot(element: ViewElement(view: window))
        presentWithSnapshot(
            snapshot,
            rootViewController: window.rootViewController,
            configuration: configuration,
            completion: completion
        )
    }

    /// Takes a snapshot of the specified view and presents the debugger view controller
    /// from the nearest ancestor view controller.
    ///
    /// - Parameters:
    ///   - view: The view controller whose view should be snapshotted.
    ///   - configuration: Optional configuration for the view debugger.
    ///   - completion: Completion block to be called once the view debugger has
    ///   been presented.
    final class func presentForView(
        _ view: UIView?,
        configuration: Configuration? = nil,
        completion: (() -> Void)? = nil
    ) {
        guard let view else {
            return
        }
        let snapshot = Snapshot(element: ViewElement(view: view))
        presentWithSnapshot(snapshot, rootViewController: getNearestAncestorViewController(responder: view), configuration: configuration, completion: completion)
    }

    /// Takes a snapshot of the view of the specified view controller and presents
    /// the debugger view controller.
    ///
    /// - Parameters:
    ///   - viewController: The view controller whose view should be snapshotted.
    ///   - configuration: Optional configuration for the view debugger.
    ///   - completion: Completion block to be called once the view debugger has
    ///   been presented.
    final class func presentForViewController(_ viewController: UIViewController?, configuration: Configuration? = nil, completion: (() -> Void)? = nil) {
        guard let view = viewController?.view else {
            return
        }
        let snapshot = Snapshot(element: ViewElement(view: view))
        presentWithSnapshot(snapshot, rootViewController: viewController, configuration: configuration, completion: completion)
    }

    /// Presents a view debugger for the a snapshot as a modal view controller on
    /// top of the specified root view controller.
    ///
    /// - Parameters:
    ///   - snapshot: The snapshot to render.
    ///   - rootViewController: The root view controller to present the debugger view
    ///   controller from.
    ///   - configuration: Optional configuration for the view debugger.
    ///   - completion: Completion block to be called once the view debugger has
    ///   been presented.
    final class func presentWithSnapshot(
        _ snapshot: Snapshot,
        rootViewController _: UIViewController?,
        configuration: Configuration? = nil,
        completion: (() -> Void)? = nil
    ) {
        let debuggerViewController = ViewDebuggerViewController(
            snapshot: snapshot,
            configuration: configuration ?? Configuration()
        )
        let navigationController = UINavigationController(rootViewController: debuggerViewController)
        navigationController.modalPresentationStyle = .fullScreen
        WindowManager.rootNavigation?.present(
            navigationController,
            animated: true,
            completion: completion
        )
    }

    @available(*, unavailable)
    override init() {
        fatalError()
    }
}
