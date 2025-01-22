//
//  MenuViewController.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

public final class SideMenuDismissTransition: NSObject,
    UIViewControllerAnimatedTransitioning {
    public init(
        menuAnimator: SideMenuAnimating,
        viewAnimator: UIViewAnimating.Type
    ) {
        self.menuAnimator = menuAnimator
        self.viewAnimator = viewAnimator
        super.init()
    }

    let menuAnimator: SideMenuAnimating
    let viewAnimator: UIViewAnimating.Type

    public func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    public func animateTransition(using context: UIViewControllerContextTransitioning) {
        viewAnimator.animate(
            withDuration: transitionDuration(using: context),
            animations: {
                self.menuAnimator.animate(in: context.containerView, to: 0)
            },
            completion: { _ in
                let isCancelled = context.transitionWasCancelled
                context.completeTransition(isCancelled == false)
            }
        )
    }
}
