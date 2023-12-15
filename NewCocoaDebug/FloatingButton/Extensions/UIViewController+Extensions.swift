//
//  UIViewController+Extensions.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 26/11/21.
//  Copyright © 2021 apple. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(with message: String, title: String = "Atenção", leftButtonTitle: String? = nil, leftButtonStyle: UIAlertAction.Style = .destructive, leftButtonHandler: ((UIAlertAction) -> Void)? = nil, rightButtonTitle: String = "OK", rightButtonStyle: UIAlertAction.Style = .default, rightButtonHandler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: rightButtonTitle, style: rightButtonStyle, handler: rightButtonHandler))

        if let leftButtonTitle = leftButtonTitle {
            alertController.addAction(UIAlertAction(title: leftButtonTitle, style: leftButtonStyle, handler: leftButtonHandler))
        }

        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }

    func addRightBarButton(image: UIImage?, completion: (() -> Void)? = nil) {
        let rightButton = CustomBarButtonItem(image: image, style: .plain) { _ in
            if let completion = completion {
                completion()
            }
        }
        navigationItem.rightBarButtonItem = rightButton
    }

    func addLeftBarButton(image: UIImage?, completion: (() -> Void)? = nil) {
        let backButton = CustomBarButtonItem(image: image, style: .plain) { _ in
            if let completion = completion {
                completion()
                return
            }
        }
        navigationItem.leftBarButtonItem = backButton
    }
}

// MARK: - Helpers

final class CustomBarButtonItem: UIBarButtonItem {

    typealias UIBarButtonItemTargetClosure = (UIBarButtonItem) -> Void

    private var targetClosure: UIBarButtonItemTargetClosure?

    convenience init(title: String?, style: UIBarButtonItem.Style = .plain, closure: UIBarButtonItemTargetClosure?) {
        self.init(title: title, style: style, target: nil, action: #selector(CustomBarButtonItem.closureAction(sender:)))
        target = self
        self.targetClosure = closure
    }

    convenience init(image: UIImage?, style: UIBarButtonItem.Style = .plain, closure: UIBarButtonItemTargetClosure?) {
        self.init(image: image, style: style, target: nil, action: #selector(CustomBarButtonItem.closureAction(sender:)))
        target = self
        self.targetClosure = closure
    }

    @objc func closureAction(sender: UIBarButtonItem) {
        targetClosure?(sender)
    }
}

extension UINavigationController {
    func pushViewController(viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        pushViewController(viewController, animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }

    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}
