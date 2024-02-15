//
//  BaseController.swift
//  LaunchTimeTracker
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class BaseController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = Theme.shared.interfaceStyleColor
        }
    }

    init(withNib _: Bool) {
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = Theme.shared.interfaceStyleColor
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
