//
//  TransitionPop.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2023/12/12.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class TransitionPop: NSObject, UIViewControllerAnimatedTransitioning {
    var transitionCtx: UIViewControllerContextTransitioning?

    func transitionDuration(using _: UIViewControllerContextTransitioning?)
        -> TimeInterval {
        DSFloatChat.animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionCtx = transitionContext

        guard let fromVC = transitionContext.viewController(
            forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        else {
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        containerView.addSubview(fromVC.view)

        let ballRect = FloatViewManager.shared.ballView.frame
        let startAnimationPath = UIBezierPath(roundedRect: toVC.view.bounds, cornerRadius: 0.1)
        let endAnimationPath = UIBezierPath(
            roundedRect: ballRect, cornerRadius: ballRect.size.height / 2
        )

        let maskLayer = CAShapeLayer()
        maskLayer.path = endAnimationPath.cgPath
        fromVC.view.layer.mask = maskLayer

        let basicAnimation = CABasicAnimation(keyPath: "path")
        basicAnimation.fromValue = startAnimationPath.cgPath
        basicAnimation.toValue = endAnimationPath.cgPath
        basicAnimation.delegate = self
        basicAnimation.duration = DSFloatChat.animationDuration
        basicAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        maskLayer.add(basicAnimation, forKey: "pathAnimation")
    }
}

// MARK: - Animation end callback

extension TransitionPop: CAAnimationDelegate {
    func animationDidStop(_: CAAnimation, finished _: Bool) {
        transitionCtx?.completeTransition(true)
        transitionCtx?.view(forKey: UITransitionContextViewKey.from)?.layer.mask = nil
        transitionCtx?.view(forKey: UITransitionContextViewKey.to)?.layer.mask = nil
        /// Show ball
        if FloatViewManager.shared.ballView.changeStatusInNextTransaction {
            FloatViewManager.shared.ballView.show = true
        } else {
            FloatViewManager.shared.ballView.changeStatusInNextTransaction = true
        }
    }
}
