//
//  PushNotification.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

class PushNotificationController: BaseController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        return tableView
    }()
    
    private enum Section: Int, CaseIterable {
        case status = 0
        case quickActions = 1
        case templates = 2
        case history = 3
        case configuration = 4
        
        var title: String {
            switch self {
            case .status: return "Status"
            case .quickActions: return "Quick Actions"
            case .templates: return "Templates"
            case .history: return "Notification History"
            case .configuration: return "Configuration"
            }
        }
        
        var headerHeight: CGFloat {
            return 44.0
        }
    }
    
    private let simulator = PushNotificationSimulator.shared
    private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupObservers()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNotificationPermissionStatus()
    }
    
    private func updateNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { @Sendable [weak self] settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                self?.notificationPermissionStatus = status
                self?.tableView.reloadData()
            }
        }
    }
    
    private func setupUI() {
        title = "📱 Push Notifications"
        
        // Add a quick test button to navigation
        let testButton = UIBarButtonItem(
            title: "Test",
            style: .plain,
            target: self,
            action: #selector(showQuickTestAlert)
        )
        navigationItem.rightBarButtonItem = testButton
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(MenuSwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupObservers() {
        // Observer for notification changes would go here if needed
    }
    
    private func setupConstraints() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func showQuickTestAlert() {
        let alert = UIAlertController(title: "Quick Test", message: "Choose a quick test scenario", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Simple Message", style: .default) { _ in
            DebugSwift.PushNotification.simulate(title: "Test Message", body: "This is a test notification")
        })
        
        alert.addAction(UIAlertAction(title: "Message with Badge", style: .default) { _ in
            DebugSwift.PushNotification.simulate(
                title: "New Message",
                body: "You have a new message",
                badge: 1,
                sound: "default"
            )
        })
        
        alert.addAction(UIAlertAction(title: "Delayed Notification (5s)", style: .default) { _ in
            DebugSwift.PushNotification.simulate(
                title: "Delayed Message",
                body: "This notification appeared after 5 seconds",
                delay: 5.0
            )
        })
        
        alert.addAction(UIAlertAction(title: "Test Scenario - Messages", style: .default) { _ in
            DS.PushNotification.runTestScenario(.messageFlow)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension PushNotificationController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .status:
            return 2 // Enable/Disable + Permission Status
        case .quickActions:
            return 4 // Create, Templates, Test Scenarios, Clear History
        case .templates:
            return min(simulator.templates.count + 1, 6) // Show max 5 templates + "View All"
        case .history:
            return min(simulator.notificationHistory.count + 1, 6) // Show max 5 recent + "View All"
        case .configuration:
            return 3 // Settings, Permissions, About
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .status:
            return statusCellForRow(at: indexPath.row)
        case .quickActions:
            return quickActionCellForRow(at: indexPath.row)
        case .templates:
            return templateCellForRow(at: indexPath.row)
        case .history:
            return historyCellForRow(at: indexPath.row)
        case .configuration:
            return configurationCellForRow(at: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        return sectionType.title
    }
}

// MARK: - Cell Creation Methods

extension PushNotificationController {
    
    private func statusCellForRow(at row: Int) -> UITableViewCell {
        switch row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as? MenuSwitchTableViewCell else {
                return UITableViewCell()
            }
            
            cell.titleLabel.text = "Enable Simulation"
            cell.valueSwitch.isOn = simulator.isEnabled
            cell.delegate = self
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
            cell.textLabel?.text = "Permission Status"
            
            let status: String
            let color: UIColor
            
            switch notificationPermissionStatus {
            case .authorized:
                status = "✅ Authorized"
                color = .systemGreen
            case .denied:
                status = "❌ Denied"
                color = .systemRed
            case .notDetermined:
                status = "⏳ Not Determined"
                color = .systemOrange
            case .provisional:
                status = "⚠️ Provisional"
                color = .systemYellow
            case .ephemeral:
                status = "📱 Ephemeral"
                color = .systemBlue
            @unknown default:
                status = "❓ Unknown"
                color = .systemGray
            }
            
            cell.detailTextLabel?.text = status
            cell.detailTextLabel?.textColor = color
            cell.selectionStyle = .none
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    private func quickActionCellForRow(at row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
        
        switch row {
        case 0:
            cell.textLabel?.text = "➕ Create Notification"
            cell.accessoryType = .disclosureIndicator
        case 1:
            cell.textLabel?.text = "📋 Manage Templates"
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.textLabel?.text = "🎭 Test Scenarios"
            cell.accessoryType = .disclosureIndicator
        case 3:
            cell.textLabel?.text = "🗑️ Clear History"
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .none
        default:
            break
        }
        
        return cell
    }
    
    private func templateCellForRow(at row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
        
        if row < simulator.templates.count {
            let template = simulator.templates[row]
            cell.textLabel?.text = template.name
            cell.detailTextLabel?.text = template.title
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = "View All Templates (\(simulator.templates.count))"
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .systemBlue
        }
        
        return cell
    }
    
    private func historyCellForRow(at row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
        
        if row < simulator.notificationHistory.count {
            let notification = simulator.notificationHistory[row]
            cell.textLabel?.text = notification.title
            cell.detailTextLabel?.text = "\(notification.status.emoji) \(notification.status.rawValue)"
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = "View All History (\(simulator.notificationHistory.count))"
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .systemBlue
        }
        
        return cell
    }
    
    private func configurationCellForRow(at row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
        
        switch row {
        case 0:
            cell.textLabel?.text = "⚙️ Settings"
            cell.accessoryType = .disclosureIndicator
        case 1:
            cell.textLabel?.text = "🔔 Request Permissions"
            cell.accessoryType = .none
        case 2:
            cell.textLabel?.text = "ℹ️ About Push Simulation"
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PushNotificationController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .status:
            handleStatusSelection(at: indexPath.row)
        case .quickActions:
            handleQuickActionSelection(at: indexPath.row)
        case .templates:
            handleTemplateSelection(at: indexPath.row)
        case .history:
            handleHistorySelection(at: indexPath.row)
        case .configuration:
            handleConfigurationSelection(at: indexPath.row)
        }
    }
    
    private func handleStatusSelection(at row: Int) {
        if row == 1 {
            // Open system settings for notifications
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    private func handleQuickActionSelection(at row: Int) {
        switch row {
        case 0:
            let createController = PushNotificationCreateController()
            navigationController?.pushViewController(createController, animated: true)
        case 1:
            let templatesController = PushNotificationTemplatesController()
            navigationController?.pushViewController(templatesController, animated: true)
        case 2:
            showTestScenariosActionSheet()
        case 3:
            showClearHistoryAlert()
        default:
            break
        }
    }
    
    private func handleTemplateSelection(at row: Int) {
        if row < simulator.templates.count {
            let template = simulator.templates[row]
            showTemplateActionSheet(for: template)
        } else {
            let templatesController = PushNotificationTemplatesController()
            navigationController?.pushViewController(templatesController, animated: true)
        }
    }
    
    private func handleHistorySelection(at row: Int) {
        if row < simulator.notificationHistory.count {
            let notification = simulator.notificationHistory[row]
            showNotificationDetailAlert(for: notification)
        } else {
            let historyController = PushNotificationHistoryController()
            navigationController?.pushViewController(historyController, animated: true)
        }
    }
    
    private func handleConfigurationSelection(at row: Int) {
        switch row {
        case 0:
            let settingsController = PushNotificationSettingsController()
            navigationController?.pushViewController(settingsController, animated: true)
        case 1:
            DebugSwift.PushNotification.enableSimulation()
            tableView.reloadData()
        case 2:
            showAboutAlert()
        default:
            break
        }
    }
}

// MARK: - Action Sheets and Alerts

extension PushNotificationController {
    
    private func showTestScenariosActionSheet() {
        let alert = UIAlertController(title: "Test Scenarios", message: "Choose a scenario to test", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "📱 Message Flow", style: .default) { _ in
            DS.PushNotification.runTestScenario(.messageFlow)
        })
        
        alert.addAction(UIAlertAction(title: "📰 News Updates", style: .default) { _ in
            DS.PushNotification.runTestScenario(.newsUpdates)
        })
        
        alert.addAction(UIAlertAction(title: "🛍️ Marketing Campaign", style: .default) { _ in
            DS.PushNotification.runTestScenario(.marketingCampaign)
        })
        
        alert.addAction(UIAlertAction(title: "⚠️ System Alerts", style: .default) { _ in
            DS.PushNotification.runTestScenario(.systemAlerts)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 2, section: 1))
        }
        
        present(alert, animated: true)
    }
    
    private func showTemplateActionSheet(for template: NotificationTemplate) {
        let alert = UIAlertController(title: template.name, message: template.title, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "🚀 Send Now", style: .default) { _ in
            DebugSwift.PushNotification.simulateFromTemplate(template.name)
        })
        
        alert.addAction(UIAlertAction(title: "⏰ Send in 5s", style: .default) { _ in
            DebugSwift.PushNotification.simulateFromTemplate(template.name, delay: 5.0)
        })
        
        alert.addAction(UIAlertAction(title: "✏️ Edit Template", style: .default) { _ in
            // Navigate to edit template
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
        }
        
        present(alert, animated: true)
    }
    
    private func showClearHistoryAlert() {
        let alert = UIAlertController(
            title: "Clear History",
            message: "Are you sure you want to clear all notification history?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            DebugSwift.PushNotification.clearHistory()
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showNotificationDetailAlert(for notification: SimulatedNotification) {
        let message = """
        Status: \(notification.status.emoji) \(notification.status.rawValue)
        Trigger: \(notification.trigger.description)
        Scheduled: \(DateFormatter.localizedString(from: notification.scheduledDate, dateStyle: .short, timeStyle: .short))
        """
        
        let alert = UIAlertController(title: notification.title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Simulate Interaction", style: .default) { _ in
            DebugSwift.PushNotification.simulateInteraction(identifier: notification.id)
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            DebugSwift.PushNotification.removeNotification(id: notification.id)
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showAboutAlert() {
        let message = """
        Push Notification Simulation allows you to test push notifications using local notifications without requiring a server.
        
        Features:
        • Simulate different notification types
        • Test foreground/background scenarios
        • Template management
        • Notification history tracking
        • Custom test scenarios
        
        Perfect for testing notification handling, UI responses, and user interactions during development.
        """
        
        let alert = UIAlertController(title: "About Push Simulation", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MenuSwitchTableViewCellDelegate

extension PushNotificationController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(_ cell: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        if isOn {
            DebugSwift.PushNotification.enableSimulation()
        } else {
            DebugSwift.PushNotification.disableSimulation()
        }
        tableView.reloadData()
    }
} 
