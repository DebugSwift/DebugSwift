//
//  ZZFloatViewManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2023/12/12.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class FloatViewManager: NSObject {

    // Properties

    static let shared = FloatViewManager()

    let bottomFloatView = BottomFloatView()
    let ballView = FloatBallView()
    let ballRedCancelView = BottomFloatView()

    private var floatViewController: UIViewController?

    required override init() {
        super.init()
        currentNavigationController()?.delegate = self

        setup()
        ballMoveEvents()
    }

    static func setup(_ viewController: UIViewController) {
        shared.floatViewController = viewController
    }

    static func increment() {
        shared.ballView.increment()
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

    func toggle() {
        FloatViewManager.shared.ballView.show.toggle()
    }
}

fileprivate extension FloatViewManager {
    func setup() {
        bottomFloatView.frame = .init(x: DSFloatChat.screenWidth, y: DSFloatChat.screenHeight, width: DSFloatChat.bottomViewFloatWidth, height: DSFloatChat.bottomViewFloatHeight)
        DSFloatChat.window?.addSubview(bottomFloatView)

        ballRedCancelView.frame = .init(x: DSFloatChat.screenWidth, y: DSFloatChat.screenHeight, width: DSFloatChat.bottomViewFloatWidth, height: DSFloatChat.bottomViewFloatHeight)
        ballRedCancelView.type = BottomFloatViewType.red
        DSFloatChat.window?.addSubview(ballRedCancelView)

        ballView.frame = DSFloatChat.ballRect
        ballView.delegate = self
    }

    func ballMoveEvents() {
        // Circular reference
        ballView.ballDidSelect = { [weak self] in
            guard let self = self else { return }

            if let viewController = self.floatViewController {
                // Prevent clicks
                UIApplication.shared.beginIgnoringInteractionEvents()

                if let navigationController = self.currentNavigationController() {
                    navigationController.pushViewController(viewController, animated: true)
                } else {
                    // Create a new navigation controller if there isn't one
                    let newNavigationController = UINavigationController(rootViewController: viewController)
                    newNavigationController.modalPresentationStyle = .fullScreen
                    UIApplication.topViewController()?.present(
                        newNavigationController,
                        animated: true,
                        completion: nil
                    )
                }

                UIApplication.shared.endIgnoringInteractionEvents()
            }
        }
    }
}
extension FloatViewManager: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        // Animate only for effect VCs, ignore other VCs
        if operation == .push {
            guard toVC == floatViewController else { return nil }
            return TransitionPush()

        } else if operation == .pop {
            guard fromVC == floatViewController else { return nil }
            return TransitionPop()

        } else {
            return nil
        }
    }
}

extension FloatViewManager: FloatViewDelegate {
    func floatViewBeginMove(floatView: FloatBallView, point: CGPoint) {
        UIView.animate(withDuration: 0.2, animations: {
            self.ballRedCancelView.frame = CGRect(
                x: DSFloatChat.screenWidth - DSFloatChat.bottomViewFloatWidth,
                y: DSFloatChat.screenHeight - DSFloatChat.bottomViewFloatHeight,
                width: DSFloatChat.bottomViewFloatWidth,
                height: DSFloatChat.bottomViewFloatHeight
            )
        }) { _ in }
    }

    func floatViewMoved(floatView: FloatBallView, point: CGPoint) {
        guard let transformBottomP = DSFloatChat.window?.convert(ballView.center, to: ballRedCancelView) else {
            return
        }

        if transformBottomP.x > .zero && transformBottomP.y > .zero {
            let arcCenter = CGPoint(x: DSFloatChat.bottomViewFloatWidth, y: DSFloatChat.bottomViewFloatHeight)
            let distance = pow((transformBottomP.x - arcCenter.x), 2) + pow((transformBottomP.y - arcCenter.y), 2)
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

    func floatViewCancelMove(floatView: FloatBallView) {
        if ballRedCancelView.insideBottomSelected {
            ballView.show = false
        }

        UIView.animate(withDuration: DSFloatChat.animationCancelMoveDuration, animations: {
            self.ballRedCancelView.frame = .init(
                x: DSFloatChat.screenWidth,
                y: DSFloatChat.screenHeight,
                width: DSFloatChat.bottomViewFloatWidth,
                height: DSFloatChat.bottomViewFloatHeight
            )
        }) { _ in }
    }
}
