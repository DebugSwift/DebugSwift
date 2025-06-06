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
        tableView.backgroundColor = UIColor.black
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
        title = "App"
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

    func numberOfSections(in _: UITableView) -> Int {
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
            case .loadedLibraries:
                let controller = LoadedLibrariesViewController()
                navigationController?.pushViewController(controller, animated: true)
            case .pushNotifications:
                let controller = PushNotificationController()
                navigationController?.pushViewController(controller, animated: true)
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
                return "Device Info"
            case .actions:
                return "Actions"
            case .customData:
                return "Custom Data"
            case .customAction:
                return "Custom Actions"
            }
        }
    }
}

extension AppViewController {
    enum ActionInfo: Int, CaseIterable {
        case crash
        case console
        case location
        case loadedLibraries
        case pushNotifications

        var title: String {
            switch self {
            case .location:
                return "Simulated location"
            case .console:
                return "Console"
            case .crash:
                return "Crashes"
            case .loadedLibraries:
                return "Loaded Libraries"
            case .pushNotifications:
                return "Push Notifications"
            }
        }

        static var allCasesWithPermission: [ActionInfo] {
            var actions = ActionInfo.allCases
            let disabledActions = DebugSwift.App.shared.disableMethods

            if disabledActions.contains(.crashManager) {
                actions.removeAll(where: { $0 == .crash })
            }

            if disabledActions.contains(.location) {
                actions.removeAll(where: { $0 == .location })
            }

            if disabledActions.contains(.console) {
                actions.removeAll(where: { $0 == .console })
            }

            if disabledActions.contains(.pushNotifications) {
                actions.removeAll(where: { $0 == .pushNotifications })
            }

            return actions
        }
    }
}
