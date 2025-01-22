//
//  MenuViewController.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

public protocol SideMenuPresenting {
    func setup(in viewController: UIViewController)
    func present(from viewController: UIViewController)
}

public final class SideMenuPresenter: NSObject,
    SideMenuPresenting,
    UIViewControllerTransitioningDelegate {

    let menuViewControllerFactory: UIViewController
    let presentInteractor: SideMenuPresentInteracting
    let dismissInteractor: SideMenuDismissInteracting
    let menuAnimator: SideMenuAnimating
    let viewAnimator: UIViewAnimating.Type

    public init(
        menuViewControllerFactory: UIViewController,
        presentInteractor: SideMenuPresentInteracting = SideMenuPresentInteractor(),
        dismissInteractor: SideMenuDismissInteracting = SideMenuDismissInteractor(),
        menuAnimator: SideMenuAnimating = SideMenuAnimator(),
        viewAnimator: UIViewAnimating.Type = UIView.self
    ) {
        self.menuViewControllerFactory = menuViewControllerFactory
        self.presentInteractor = presentInteractor
        self.dismissInteractor = dismissInteractor
        self.menuAnimator = menuAnimator
        self.viewAnimator = viewAnimator
        super.init()
    }

    public func setup(in viewController: UIViewController) {
        presentInteractor.setup(
            view: viewController.view,
            action: { [weak self] in
                self?.present(from: viewController)
            }
        )
    }

    public func present(from viewController: UIViewController) {
        let menuViewController = menuViewControllerFactory
        menuViewController.modalPresentationStyle = .overFullScreen
        menuViewController.transitioningDelegate = self
        viewController.present(menuViewController, animated: true)
    }

    public func animationController(
        forPresented _: UIViewController,
        presenting _: UIViewController,
        source _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        SideMenuPresentTransition(
            dismissInteractor: dismissInteractor,
            menuAnimator: menuAnimator,
            viewAnimator: viewAnimator
        )
    }

    public func animationController(
        forDismissed _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        SideMenuDismissTransition(
            menuAnimator: menuAnimator,
            viewAnimator: viewAnimator
        )
    }

    public func interactionControllerForPresentation(
        using _: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        presentInteractor.interactionInProgress ? presentInteractor.percentDrivenInteractiveTransition : nil
    }

    public func interactionControllerForDismissal(
        using _: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        dismissInteractor.interactionInProgress ? dismissInteractor.percentDrivenInteractiveTransition : nil
    }
}
