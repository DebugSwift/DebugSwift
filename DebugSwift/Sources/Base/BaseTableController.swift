//
//  BaseTableController.swift
//  LaunchTimeTracker
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class BaseTableController: UITableViewController {
    var isViewVisible = false

    init() {
        super.init(style: .grouped)
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAppearance()
        isViewVisible = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isViewVisible = false
    }

    func configureAppearance() {
        configureNavigationBar()
        UserInterfaceToolkit.registerViewControllerForInterfaceStyleUpdates(self)
    }
}
