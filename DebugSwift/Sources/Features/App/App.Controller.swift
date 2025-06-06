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
        setupNavigationBar()
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
    
    func setupNavigationBar() {
        // Add refresh button to navigation bar
        let refreshButton = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshDeviceInfo)
        )
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    @objc private func refreshDeviceInfo() {
        Task { @MainActor in
            await APNSTokenManager.shared.refreshRegistrationStatus()
            tableView.reloadData()
            showToast(message: "Device info refreshed")
        }
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch Sections(rawValue: indexPath.section) {
        case .infos:
            handleDeviceInfoTap(at: indexPath)
            
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
    
    private func handleDeviceInfoTap(at indexPath: IndexPath) {
        let info = viewModel.infos[indexPath.row]
        
        // Check if this is the APNS token row
        if info.title == "Push Token:" {
            handleAPNSTokenTap()
        }
    }
    
    private func handleAPNSTokenTap() {
        let tokenManager = APNSTokenManager.shared
        
        switch tokenManager.registrationState {
        case .registered:
            if tokenManager.copyTokenToClipboard() {
                showToast(message: "📋 APNS token copied to clipboard")
            } else {
                showToast(message: "❌ No token available to copy")
            }
            
        case .failed:
            // Show detailed error information
            let errorMessage = tokenManager.registrationError ?? "Unknown error"
            let alert = UIAlertController(
                title: "Push Notification Registration Failed",
                message: "Error: \(errorMessage)\n\nTo resolve this, check your app's push notification configuration in Apple Developer Console.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            
        case .notRequested, .pending:
            // Offer to request permissions
            let alert = UIAlertController(
                title: "Push Notifications Not Set Up",
                message: "This app hasn't requested push notification permissions yet. Would you like to refresh and check again?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Refresh", style: .default) { [weak self] _ in
                self?.refreshDeviceInfo()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            
        case .denied:
            // Show instructions to enable in Settings
            let alert = UIAlertController(
                title: "Push Notifications Disabled",
                message: "Push notifications are disabled for this app. To enable them, go to Settings > Notifications > \(Bundle.main.displayName ?? "This App") and turn on notifications.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
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
