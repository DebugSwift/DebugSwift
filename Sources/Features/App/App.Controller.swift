//
//  App.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class AppViewController: BaseController {

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .gray

        return tableView
    }()

    private let viewModel = AppViewModel()

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }

    func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: .cell
        )

        tableView.register(
            MenuSwitchTableViewCell.self,
            forCellReuseIdentifier: MenuSwitchTableViewCell.identifier
        )

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setup() {
        title = "App"
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "app"),
            tag: 4
        )
    }
}
extension AppViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.infos.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: .cell,
            for: indexPath
        )
        let info = viewModel.infos[indexPath.row]
        cell.setup(
            title: info.title,
            description: info.detail,
            image: nil
        )
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
}
