//
//  Interface.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class InterfaceViewController: BaseController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray

        return tableView
    }()

    override init() {
        super.init()
        setupTabBar()
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

        view.backgroundColor = .black
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupTabBar() {
        title = "interface-title".localized()
        tabBarItem = UITabBarItem(
            title: title,
            image: .named("square.grid.2x2"),
            tag: 3
        )
    }
}

extension InterfaceViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        Features.allCases.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let feature = Features(rawValue: indexPath.row)
        let title = feature?.title ?? ""

        switch feature {
        case .grid:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: .cell,
                for: indexPath
            )
            cell.setup(title: title)
            return cell
        case .touches, .colorize, .animations:
            return toggleCell(
                title: title,
                index: indexPath.row
            )
        default:
            return .init()
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controller: UIViewController?
        switch Features(rawValue: indexPath.row) {
        case .grid:
            controller = InterfaceGridController()
        default:
            break
        }
        if let controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension InterfaceViewController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(_ cell: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        switch Features(rawValue: cell.tag) {
        case .colorize:
            UserInterfaceToolkit.colorizedViewBordersEnabled = isOn

        case .animations:
            UserInterfaceToolkit.shared.slowAnimationsEnabled = isOn

        case .touches:
            UserInterfaceToolkit.shared.showingTouchesEnabled = isOn

        default: break
        }
    }

    private func toggleCell(
        title: String?,
        index: Int
    ) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: MenuSwitchTableViewCell.identifier
            ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = title
        cell.tag = index
        //        TODO: - Create
        //        cell.valueSwitch.isOn = performanceToolkit.isWidgetShown
        cell.delegate = self
        return cell
    }
}

extension InterfaceViewController {
    enum Features: Int, CaseIterable {
        case colorize
        case animations
        case touches
        case grid

        var title: String {
            switch self {
            case .touches:
                return "showing-touches".localized()
            case .grid:
                return "grid-overlay".localized()
            case .colorize:
                return "colorized-view-borders".localized()
            case .animations:
                return "slow-animations".localized()
            }
        }
    }
}
