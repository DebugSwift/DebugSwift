//
//  App.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class AppViewController: BaseController, MainFeatureType {

    var controllerType: DebugSwiftFeature { .app }

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = Theme.shared.backgroundColor
        tableView.separatorColor = .darkGray

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
        title = "app-title".localized()
        tabBarItem = UITabBarItem(
            title: title,
            image: .named("app"),
            tag: 4
        )
    }
}

extension AppViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section) {
        case .infos:
            return viewModel.infos.count
        case .customData:
            return viewModel.customInfos.count
        case .actions:
            return ActionInfo.allCasesWithPermission.count
        case .customAction:
            return viewModel.customActions.count
        case nil:
            return .zero
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        Sections.allCases.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: .cell,
            for: indexPath
        )
        switch Sections(rawValue: indexPath.section) {
        case .infos:
            let info = viewModel.infos[indexPath.row]
            cell.setup(
                title: info.title,
                description: info.detail,
                image: nil
            )
            return cell
        case .actions:
            cell.setup(
                title: ActionInfo.allCasesWithPermission[indexPath.row].title
            )
        case .customData:
            let info = viewModel.customInfos[indexPath.row]
            cell.setup(title: info.title)
            return cell

        case .customAction:
            let info = viewModel.customActions[indexPath.row]
            cell.setup(title: info.title)
            return cell

        case nil:
            break
        }

        return cell
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.getTitle(for: section)
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Sections(rawValue: indexPath.section) {
        case .customData:
            let data = viewModel.customInfos[indexPath.row]
            let viewModel = AppCustomInfoViewModel(data: data)
            let controller = ResourcesGenericController(viewModel: viewModel)
            navigationController?.pushViewController(controller, animated: true)

        case .customAction:
            let data = viewModel.customActions[indexPath.row]
            let viewModel = AppCustomActionViewModel(data: data)
            let controller = ResourcesGenericController(viewModel: viewModel)
            navigationController?.pushViewController(controller, animated: true)

        case .actions:
            switch ActionInfo.allCasesWithPermission[indexPath.row] {
            case .console:
                let viewModel = AppConsoleViewModel()
                let controller = ResourcesGenericController(viewModel: viewModel)
                navigationController?.pushViewController(controller, animated: true)
            case .location:
                let controller = LocationViewController()
                navigationController?.pushViewController(controller, animated: true)
            case .crash:
                let controller = CrashViewController()
                navigationController?.pushViewController(controller, animated: true)
            default: break
            }
        default:
            break
        }
    }
}

extension AppViewController {
    enum Sections: Int, CaseIterable {
        case actions
        case customAction
        case customData
        case infos

        var title: String? {
            switch self {
            case .infos:
                return "device-info".localized()
            case .actions:
                return "actions".localized()
            case .customData:
                return "custom-data".localized()
            case .customAction:
                return "custom-action".localized()
            }
        }
    }
}

extension AppViewController {
    enum ActionInfo: Int, CaseIterable {
        case crash
        case console
        case location

        var title: String {
            switch self {
            case .location:
                return "simulated-location".localized()
            case .console:
                return "actions-console".localized()
            case .crash:
                return "actions-crash".localized()
            }
        }

        static var allCasesWithPermission: [ActionInfo] {
            var actions = ActionInfo.allCases
            let disabledActions = DebugSwift.App.disableMethods

            if disabledActions.contains(.crashManager) {
                actions.removeAll(where: { $0 == .crash })
            }

            if disabledActions.contains(.location) {
                actions.removeAll(where: { $0 == .location })
            }

            if disabledActions.contains(.console) {
                actions.removeAll(where: { $0 == .console })
            }

            return actions
        }
    }
}
