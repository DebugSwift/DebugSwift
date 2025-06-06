//
//  PushNotificationHistoryController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

// MARK: - UIColor Extension for Hex Support

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: 1)
                    return
                }
            }
        }
        
        return nil
    }
}

@MainActor
class PushNotificationHistoryController: BaseController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        return tableView
    }()
    
    private let simulator = PushNotificationSimulator.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupUI() {
        title = "Notification History"
        
        // Add clear all button
        let clearButton = UIBarButtonItem(
            title: "Clear All",
            style: .plain,
            target: self,
            action: #selector(clearAllTapped)
        )
        navigationItem.rightBarButtonItem = clearButton
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func clearAllTapped() {
        let alert = UIAlertController(
            title: "Clear All History",
            message: "Are you sure you want to clear all notification history? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            DebugSwift.PushNotification.clearHistory()
            self?.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
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
    
    @objc private func refreshData() {
        tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
    }
}

// MARK: - UITableViewDataSource

extension PushNotificationHistoryController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = simulator.notificationHistory.count
        
        if count == 0 {
            // Show empty state
            let emptyLabel = UILabel()
            emptyLabel.text = "No notifications yet\nTap 'Create Notification' to get started"
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            emptyLabel.textColor = .systemGray
            emptyLabel.font = UIFont.systemFont(ofSize: 16)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let notification = simulator.notificationHistory[indexPath.row]
        
        // Configure cell appearance
        cell.textLabel?.text = notification.title
        cell.textLabel?.numberOfLines = 1
        
        // Create detailed subtitle
        var subtitleParts: [String] = []
        
        // Add status with emoji
        subtitleParts.append("\(notification.status.emoji) \(notification.status.rawValue)")
        
        // Add trigger info
        subtitleParts.append(notification.trigger.description)
        
        // Add time
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        subtitleParts.append(timeFormatter.string(from: notification.scheduledDate))
        
        cell.detailTextLabel?.text = subtitleParts.joined(separator: " • ")
        cell.detailTextLabel?.numberOfLines = 2
        // Convert hex color to UIColor
        let hexString = notification.status.colorHex
        if let color = UIColor(hex: hexString) {
            cell.detailTextLabel?.textColor = color
        } else {
            cell.detailTextLabel?.textColor = .label
        }
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PushNotificationHistoryController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let notification = simulator.notificationHistory[indexPath.row]
        showNotificationDetail(notification)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let notification = simulator.notificationHistory[indexPath.row]
            DebugSwift.PushNotification.removeNotification(id: notification.id)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let notification = simulator.notificationHistory[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            var actions: [UIAction] = []
            
            // Simulate interaction action
            let interactAction = UIAction(
                title: "Simulate Interaction",
                image: UIImage(systemName: "hand.tap")
            ) { _ in
                DebugSwift.PushNotification.simulateInteraction(identifier: notification.id)
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            actions.append(interactAction)
            
            // Resend action
            let resendAction = UIAction(
                title: "Send Again",
                image: UIImage(systemName: "arrow.clockwise")
            ) { _ in
                let newNotification = SimulatedNotification(
                    title: notification.title,
                    body: notification.body,
                    subtitle: notification.subtitle,
                    badge: notification.badge,
                    sound: notification.sound,
                    userInfo: notification.userInfo,
                    trigger: .immediate
                )
                
                Task {
                    await PushNotificationSimulator.shared.simulateNotification(newNotification)
                    DispatchQueue.main.async {
                        tableView.reloadData()
                    }
                }
            }
            actions.append(resendAction)
            
            // Delete action
            let deleteAction = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                DebugSwift.PushNotification.removeNotification(id: notification.id)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            actions.append(deleteAction)
            
            return UIMenu(title: notification.title, children: actions)
        }
    }
    
    private func showNotificationDetail(_ notification: SimulatedNotification) {
        let alert = UIAlertController(title: notification.title, message: nil, preferredStyle: .alert)
        
        // Create detailed message
        var details: [String] = []
        details.append("Body: \(notification.body)")
        
        if let subtitle = notification.subtitle, !subtitle.isEmpty {
            details.append("Subtitle: \(subtitle)")
        }
        
        if let badge = notification.badge {
            details.append("Badge: \(badge)")
        }
        
        if let sound = notification.sound {
            details.append("Sound: \(sound)")
        }
        
        details.append("Status: \(notification.status.emoji) \(notification.status.rawValue)")
        details.append("Trigger: \(notification.trigger.description)")
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .short
        timeFormatter.timeStyle = .medium
        details.append("Scheduled: \(timeFormatter.string(from: notification.scheduledDate))")
        
        if let deliveryDate = notification.deliveryDate {
            details.append("Delivered: \(timeFormatter.string(from: deliveryDate))")
        }
        
        if !notification.userInfo.isEmpty {
            details.append("\nUser Info:")
            for (key, value) in notification.userInfo {
                details.append("  \(key): \(value)")
            }
        }
        
        alert.message = details.joined(separator: "\n")
        
        // Action buttons
        alert.addAction(UIAlertAction(title: "Simulate Interaction", style: .default) { _ in
            DebugSwift.PushNotification.simulateInteraction(identifier: notification.id)
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Send Again", style: .default) { _ in
            let newNotification = SimulatedNotification(
                title: notification.title,
                body: notification.body,
                subtitle: notification.subtitle,
                badge: notification.badge,
                sound: notification.sound,
                userInfo: notification.userInfo,
                trigger: .immediate
            )
            
            Task {
                await PushNotificationSimulator.shared.simulateNotification(newNotification)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DebugSwift.PushNotification.removeNotification(id: notification.id)
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(alert, animated: true)
    }
} 