//
//  ViewController.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 2023/12/12.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
    }

    fileprivate func setup() {
        title = "Increment View"
        view.backgroundColor = .white

        buildButton()
        FloatViewManager.setup(TabBarController())

    }

    fileprivate func buildButton() {
        if #available(iOS 13.0, *) {
            addLeftBarButton(buttonImage: .actions) {
                if FloatViewManager.isShowing() {
                    FloatViewManager.increment()
                } else {
                    FloatViewManager.show()
                }
            }
        }
    }

    private func setupNavigation() {
        navigationController?.navigationBar.tintColor = .systemBlue
    }
}
