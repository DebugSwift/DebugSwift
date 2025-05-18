//
//  FloatViewManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2023/12/12.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

@MainActor
final class FloatViewManager: NSObject {
    static let shared = FloatViewManager()

    let ballView = FloatBallView()
    let ballRedCancelView = BottomFloatView()

    private(set) var floatViewController: UIViewController?

    override required init() {
        super.init()
        WindowManager.rootNavigation?.delegate = self

        setup()
        setupClickEvent()
        observers()
    }

    static func setup(_ viewController: UIViewController) {
        shared.floatViewController = viewController
    }

    static func animate(success: Bool) {
        shared.ballView.animate(success: success)
    }

    static func animateLeek(alloced: Bool) {
        shared.ballView.animateLeek(alloced: alloced)
    }

    static func reset() {
        shared.ballView.reset()
    }

    static func isShowing() -> Bool {
        shared.ballView.isShowing
    }

    static func show() {
        shared.ballView.show = true
    }

    static func remove() {
        shared.ballView.show = false
    }

    static func toggle() {
        FloatViewManager.shared.ballView.show.toggle()
    }

    static var isShowingDebuggerView = false {
        didSet {
            shared.ballView.isHidden = isShowingDebuggerView
        }
    }

    func observers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "reloadHttp_DebugSwift"),
            object: nil,
            queue: .main
        ) { notification in
            if let success = notification.object as? Bool {
                Self.animate(success: success)
            }
        }
    }
}

extension FloatViewManager {
    private func setup() {
        ballRedCancelView.frame = .init(
            x: DSFloatChat.screenWidth,
            y: DSFloatChat.screenHeight,
            width: DSFloatChat.bottomViewFloatWidth,
            height: DSFloatChat.bottomViewFloatHeight
        )
        ballRedCancelView.type = BottomFloatViewType.red
        WindowManager.window.addSubview(ballRedCancelView)

        ballView.frame = DSFloatChat.ballRect
        ballView.delegate = self
    }

    private func setupClickEvent() {
        ballView.ballDidSelect = {
            WindowManager.presentDebugger()
        }
    }
}

extension FloatViewManager: UINavigationControllerDelegate {
    func navigationController(
        _: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            guard toVC == floatViewController else { return nil }
            return TransitionPush()
        }
        if operation == .pop {
            guard fromVC == floatViewController else { return nil }
            return TransitionPop()
        }
        return nil
    }
}

extension FloatViewManager: FloatViewDelegate {
    func floatViewBeginMove(floatView _: FloatBallView, point _: CGPoint) {
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.ballRedCancelView.frame = CGRect(
                    x: DSFloatChat.screenWidth - DSFloatChat.bottomViewFloatWidth,
                    y: DSFloatChat.screenHeight - DSFloatChat.bottomViewFloatHeight,
                    width: DSFloatChat.bottomViewFloatWidth,
                    height: DSFloatChat.bottomViewFloatHeight
                )
            }
        ) { _ in
        }
    }

    func floatViewMoved(floatView _: FloatBallView, point _: CGPoint) {
        let transformBottomP = WindowManager.window.convert(
            ballView.center,
            to: ballRedCancelView
        )

        if transformBottomP.x > .zero, transformBottomP.y > .zero {
            let arcCenter = CGPoint(
                x: DSFloatChat.bottomViewFloatWidth,
                y: DSFloatChat.bottomViewFloatHeight
            )
            let distance =
                pow(transformBottomP.x - arcCenter.x, 2) + pow(transformBottomP.y - arcCenter.y, 2)
            let onArc = pow(arcCenter.x, 2)

            if distance <= onArc {
                if !ballRedCancelView.insideBottomSelected {
                    ballRedCancelView.insideBottomSelected = true
                }
            } else {
                if ballRedCancelView.insideBottomSelected {
                    ballRedCancelView.insideBottomSelected = false
                }
            }
        } else {
            if ballRedCancelView.insideBottomSelected {
                ballRedCancelView.insideBottomSelected = false
            }
        }
    }

    func floatViewCancelMove(floatView _: FloatBallView) {
        if ballRedCancelView.insideBottomSelected {
            ballView.show = false
        }

        UIView.animate(
            withDuration: DSFloatChat.animationCancelMoveDuration,
            animations: {
                self.ballRedCancelView.frame = .init(
                    x: DSFloatChat.screenWidth,
                    y: DSFloatChat.screenHeight,
                    width: DSFloatChat.bottomViewFloatWidth,
                    height: DSFloatChat.bottomViewFloatHeight
                )
            }
        ) { _ in
        }
    }
}
