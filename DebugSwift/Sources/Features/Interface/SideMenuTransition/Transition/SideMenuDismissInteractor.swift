//
//  MenuViewController.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

public protocol SideMenuDismissInteracting {
    var interactionInProgress: Bool { get }
    var percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition { get }

    func setup(view: UIView, action: @escaping () -> Void)
}

public final class SideMenuDismissInteractor: NSObject, SideMenuDismissInteracting {
    override public init() {
        super.init()
    }

    var panGestureRecognizerFactory: (Any?, Selector?) -> UIPanGestureRecognizer
        = UIPanGestureRecognizer.init(target:action:)

    var tapGestureRecognizerFactory: (Any?, Selector?) -> UITapGestureRecognizer
        = UITapGestureRecognizer.init(target:action:)

    private var action: (() -> Void)?
    private var shouldFinishTransition = false

    // MARK: - SideMenuDismissInteracting

    public private(set) var interactionInProgress = false
    public internal(set) var percentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()

    public func setup(view: UIView, action: @escaping () -> Void) {
        let panRecognizer = panGestureRecognizerFactory(self, #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panRecognizer)

        let tapRecognizer = tapGestureRecognizerFactory(self, #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapRecognizer)

        self.action = action
    }

    // MARK: - Gesture handling

    @objc
    private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view,
              let containerView = view.superview
        else { return }

        let viewWidth = containerView.bounds.size.width
        guard viewWidth > 0 else { return }

        switch recognizer.state {
        case .possible, .failed:
            interactionInProgress = false

        case .began:
            interactionInProgress = true
            shouldFinishTransition = false
            action?()

        case .changed:
            let translation = recognizer.translation(in: view)
            let progress = min(1, max(0, translation.x / (viewWidth * 0.8)))

            shouldFinishTransition = progress >= 0.5
            percentDrivenInteractiveTransition.update(progress)

        case .cancelled:
            interactionInProgress = false
            percentDrivenInteractiveTransition.cancel()

        case .ended:
            interactionInProgress = false
            shouldFinishTransition ?
                percentDrivenInteractiveTransition.finish() :
                percentDrivenInteractiveTransition.cancel()

        @unknown default:
            interactionInProgress = false
            percentDrivenInteractiveTransition.cancel()
        }
    }

    @objc
    private func handleTapGesture(_: UITapGestureRecognizer) {
        action?()
    }
}
