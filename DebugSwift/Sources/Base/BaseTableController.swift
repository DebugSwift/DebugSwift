//
//  BaseTableController.swift
//  LaunchTimeTracker
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class BaseTableController: UITableViewController {
    init() {
        super.init(style: .grouped)
        configureAppearance()
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
        configureAppearance()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func configureAppearance() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = Theme.shared.interfaceStyleColor
        }
    }
}
