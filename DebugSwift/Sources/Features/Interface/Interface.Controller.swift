//
//  Interface.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class InterfaceViewController: BaseController, MainFeatureType {
    var controllerType: DebugSwiftFeature { .interface }

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray

        return tableView
    }()

    override init() {
        super.init()
        setupTabBar()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(measurementStateChanged),
            name: MeasurementWindowManager.measurementStateChangedNotification,
            object: nil
        )
    }
    
    @objc private func measurementStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
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

        view.backgroundColor = UIColor.black
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupTabBar() {
        title = "Interface"
        tabBarItem = UITabBarItem(
            title: title,
            image: .named("square.grid.2x2"),
            tag: 3
        )
    }
}

extension InterfaceViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        Features.allCasesWithPermissions.filter { $0.title != nil }.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let feature = Features.allCasesWithPermissions[indexPath.row]
        let title = feature.title ?? ""

        switch Features.allCasesWithPermissions[indexPath.row] {
        case .grid, .swiftUIRenderSettings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.setup(title: title)
            return cell
        case .touches, .colorize, .animations, .darkMode, .measurement:
            return toggleCell(
                title: title,
                index: indexPath.row,
                isOn: feature.isOn == true
            )
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controller: UIViewController?
        switch Features.allCasesWithPermissions[indexPath.row] {
        case .grid:
            controller = InterfaceGridController()
        case .swiftUIRenderSettings:
            controller = InterfaceSwiftUIRenderController()
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
        switch Features.allCasesWithPermissions[cell.tag] {
        case .colorize:
            UserInterfaceToolkit.colorizedViewBordersEnabled = isOn

        case .animations:
            UserInterfaceToolkit.shared.slowAnimationsEnabled = isOn

        case .touches:
            UserInterfaceToolkit.shared.showingTouchesEnabled = isOn

        case .darkMode:
            UserInterfaceToolkit.shared.darkModeEnabled = isOn
            
        case .measurement:
            if isOn {
                DebugSwift.Measurement.activate()
            } else {
                DebugSwift.Measurement.deactivate()
            }
            
        default: break
        }
    }

    private func toggleCell(
        title: String?,
        index: Int,
        isOn: Bool
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuSwitchTableViewCell.identifier
        ) as? MenuSwitchTableViewCell ?? .init()
        cell.titleLabel.text = title
        cell.tag = index
        cell.valueSwitch.isOn = isOn
        cell.delegate = self
        return cell
    }
}

extension InterfaceViewController {
    @MainActor
    enum Features: Int, CaseIterable {
        case colorize
        case animations
        case touches
        case grid
        case darkMode
        case measurement
        case swiftUIRenderSettings

        var title: String? {
            switch self {
            case .touches:
                return "Showing touches"
            case .grid:
                return "Grid overlay"
            case .colorize:
                return "Colorized view borders"
            case .animations:
                return "Slow animations"
            case .darkMode:
                return "Dark Mode"
            case .measurement:
                return "UI measurements"
            case .swiftUIRenderSettings:
                return "SwiftUI render tracking"
            }
        }

        var isOn: Bool {
            switch self {
            case .colorize:
                return UserInterfaceToolkit.colorizedViewBordersEnabled

            case .animations:
                return UserInterfaceToolkit.shared.slowAnimationsEnabled

            case .touches:
                return UserInterfaceToolkit.shared.showingTouchesEnabled
            case .darkMode:
                return UserInterfaceToolkit.shared.darkModeEnabled
            case .measurement:
                return DebugSwift.Measurement.isActive
            default:
                return false
            }
        }

        static var allCasesWithPermissions: [Features] {
            var cases = Features.allCases
            if DebugSwift.App.shared.disableMethods.contains(.views) {
                cases.removeAll(where: { $0 == .colorize || $0 == .touches })
            }
            
            if DebugSwift.App.shared.disableMethods.contains(.swiftUIRender) {
                cases.removeAll(where: { $0 == .swiftUIRenderSettings })
            }
            
            // Hide SwiftUI render tracking if beta features are not enabled
            if !FeatureHandling.enabledBetaFeatures.contains(.swiftUIRenderTracking) {
                cases.removeAll(where: { $0 == .swiftUIRenderSettings })
            }

            return cases
        }
    }
}
