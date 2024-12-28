//
//  UIViewController+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UIViewController {
    func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func showAlert(
        with message: String, title: String = "Warning", leftButtonTitle: String? = nil,
        leftButtonStyle: UIAlertAction.Style = .destructive,
        leftButtonHandler: ((UIAlertAction) -> Void)? = nil, rightButtonTitle: String = "OK",
        rightButtonStyle: UIAlertAction.Style = .default,
        rightButtonHandler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addAction(
            UIAlertAction(title: rightButtonTitle, style: rightButtonStyle, handler: rightButtonHandler))

        if let leftButtonTitle {
            alertController.addAction(
                UIAlertAction(title: leftButtonTitle, style: leftButtonStyle, handler: leftButtonHandler))
        }

        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }

    func addRightBarButton(
        title: String?,
        tintColor: UIColor? = nil,
        completion: (() -> Void)? = nil
    ) {
        let rightButton = CustomBarButtonItem(
            title: title,
            style: .plain
        ) { _ in
            if let completion {
                completion()
            }
        }
        if let tintColor {
            rightButton.tintColor = tintColor
        }
        navigationItem.rightBarButtonItem = rightButton
    }

    func addRightBarButton(
        image: UIImage?,
        tintColor: UIColor? = nil,
        completion: (() -> Void)? = nil
    ) {
        let rightButton = CustomBarButtonItem(
            image: image,
            style: .plain
        ) { _ in
            if let completion {
                completion()
            }
        }
        if let tintColor {
            rightButton.tintColor = tintColor
        }
        navigationItem.rightBarButtonItem = rightButton
    }

    func addRightBarButton(
        actions: [ButtonAction]
    ) {
        let rightButtons = actions.map { action in
            CustomBarButtonItem(
                image: action.image,
                tintColor: action.tintColor,
                style: .plain
            ) { _ in
                if let completion = action.completion {
                    completion()
                }
            }
        }

        navigationItem.rightBarButtonItems = rightButtons
    }

    func addLeftBarButton(
        image: UIImage?,
        tintColor: UIColor? = nil,
        completion: (() -> Void)? = nil
    ) {
        let leftButton = CustomBarButtonItem(image: image, style: .plain) { _ in
            if let completion {
                completion()
                return
            }
        }
        if let tintColor {
            leftButton.tintColor = tintColor
        }
        navigationItem.leftBarButtonItem = leftButton
    }

    func configureNavigationBar(isTranslucent: Bool = false, barTintColor: UIColor = Theme.shared.backgroundColor) {
        navigationController?.navigationBar.isTranslucent = isTranslucent
        navigationController?.navigationBar.barTintColor = barTintColor
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

// MARK: - Helpers

final class CustomBarButtonItem: UIBarButtonItem {
    typealias UIBarButtonItemTargetClosure = (UIBarButtonItem) -> Void

    private var targetClosure: UIBarButtonItemTargetClosure?

    convenience init(
        title: String?,
        style: UIBarButtonItem.Style = .plain,
        closure: UIBarButtonItemTargetClosure?
    ) {
        self.init(
            title: title, style: style, target: nil,
            action: #selector(CustomBarButtonItem.closureAction(sender:))
        )
        target = self
        self.targetClosure = closure
    }

    convenience init(
        image: UIImage?,
        tintColor: UIColor? = nil,
        style: UIBarButtonItem.Style = .plain,
        closure: UIBarButtonItemTargetClosure?
    ) {
        self.init(
            image: image,
            style: style,
            target: nil,
            action: #selector(CustomBarButtonItem.closureAction(sender:))
        )

        if let tintColor {
            self.tintColor = tintColor
        }

        target = self
        self.targetClosure = closure
    }

    @objc func closureAction(sender: UIBarButtonItem) {
        targetClosure?(sender)
    }
}

extension UIViewController {
    struct ButtonAction {
        init(
            image: UIImage? = nil,
            tintColor: UIColor? = nil,
            completion: (() -> Void)? = nil
        ) {
            self.image = image
            self.tintColor = tintColor
            self.completion = completion
        }

        let image: UIImage?
        let tintColor: UIColor?
        let completion: (() -> Void)?
    }
}
