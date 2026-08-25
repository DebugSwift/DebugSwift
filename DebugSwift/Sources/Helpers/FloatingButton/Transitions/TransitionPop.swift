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
    private weak var maskedFromView: UIView?
    private weak var maskedToView: UIView?

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
        fromVC.view.layer.mask = nil
        toVC.view.layer.mask = nil
        maskedFromView = fromVC.view
        maskedToView = toVC.view
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
    nonisolated func animationDidStop(_: CAAnimation, finished _: Bool) {
        DispatchQueue.main.async { [weak self] in

            self?.maskedFromView?.layer.mask = nil
            self?.maskedToView?.layer.mask = nil
            self?.transitionCtx?.completeTransition(true)
            self?.transitionCtx?.view(forKey: UITransitionContextViewKey.from)?.layer.mask = nil
            self?.transitionCtx?.view(forKey: UITransitionContextViewKey.to)?.layer.mask = nil
            /// Show ball
            if FloatViewManager.shared.ballView.changeStatusInNextTransaction {
                FloatViewManager.shared.ballView.show = true
            } else {
                FloatViewManager.shared.ballView.changeStatusInNextTransaction = true
            }
        }
    }
}
