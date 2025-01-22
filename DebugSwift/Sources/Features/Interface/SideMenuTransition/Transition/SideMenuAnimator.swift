//
//  MenuViewController.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

public protocol SideMenuAnimating {
    func animate(in containerView: UIView, to progress: CGFloat)
}

public struct SideMenuAnimator: SideMenuAnimating {
    public init() {}

    public func animate(in containerView: UIView, to progress: CGFloat) {
        guard let fromView = containerView.viewWithTag(SideMenuPresentTransition.fromViewTag)
        else { return }

        let cornerRadius = progress * 48
        let shadowOpacity = Float(progress)
        let offsetX = containerView.bounds.size.width * 0.5 * -progress
        let scale = 1 - (0.2 * progress)

        fromView.subviews.first?.layer.cornerRadius = cornerRadius
        fromView.layer.shadowOpacity = shadowOpacity
        fromView.transform = CGAffineTransform.identity
            .translatedBy(x: offsetX, y: 0)
            .scaledBy(x: scale, y: scale)
    }
}
