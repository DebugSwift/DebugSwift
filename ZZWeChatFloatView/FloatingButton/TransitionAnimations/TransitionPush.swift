//
//  TransitionPush.swift
//  ZZWeChatFloatView
//
//  Created by 周晓瑞 on 2018/6/12.
//  Copyright © 2018年 apple. All rights reserved.
//

import UIKit

class TransitionPush: NSObject, UIViewControllerAnimatedTransitioning {
    var transitionCtx: UIViewControllerContextTransitioning?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return DSFloatChat.animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionCtx = transitionContext

        guard let fromVC = transitionContext .viewController(forKey: UITransitionContextViewControllerKey.from),
              let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)

        let ballRect = FloatViewManager.shared.ballView.frame
        let startAnimationPath = UIBezierPath(roundedRect: ballRect, cornerRadius: ballRect.size.height/2)
        let endAnimationPath = UIBezierPath(roundedRect: toVC.view.bounds, cornerRadius: 0.1)

        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.path = endAnimationPath.cgPath
        toVC.view.layer.mask = maskLayer

        let basicAnimation = CABasicAnimation(keyPath: "path")
        basicAnimation.fromValue = startAnimationPath.cgPath
        basicAnimation.toValue = endAnimationPath.cgPath
        basicAnimation.delegate = self
        basicAnimation.duration = DSFloatChat.animationDuration
        basicAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        maskLayer.add(basicAnimation, forKey: "pathAnimation")
        /// Hidden ball
        if FloatViewManager.shared.ballView.changeStatusInNextTransaction {
            FloatViewManager.shared.ballView.show = false
        } else {
            FloatViewManager.shared.ballView.changeStatusInNextTransaction = true
        }
    }
}

// MARK: - Animation end callback

extension TransitionPush: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        transitionCtx?.completeTransition(true)
        transitionCtx?.view(forKey: UITransitionContextViewKey.from)?.layer.mask = nil
        transitionCtx?.view(forKey: UITransitionContextViewKey.to)?.layer.mask = nil
    }
}
