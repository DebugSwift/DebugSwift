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
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == .zero {
            return viewModel.infos.count
        } else {
            return viewModel.customInfos.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.customInfos.isEmpty ? 1 : 2
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: .cell,
            for: indexPath
        )
        if indexPath.section == 0 {
            let info = viewModel.infos[indexPath.row]
            cell.setup(
                title: info.title,
                description: info.detail,
                image: nil
            )
            return cell
        } else {
            let info = viewModel.customInfos[indexPath.row]
            cell.setup(title: info.title)
            return cell
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? "Custom Data" : nil
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let data = viewModel.customInfos[indexPath.row]
            let viewModel = AppCustomInfoViewModel(data: data)
            let controller = ResourcesGenericController(viewModel: viewModel)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}
