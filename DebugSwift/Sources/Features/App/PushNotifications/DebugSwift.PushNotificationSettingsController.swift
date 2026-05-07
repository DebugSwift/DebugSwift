//
//  PushNotificationSettingsController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

@MainActor
class PushNotificationSettingsController: BaseController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        return tableView
    }()
    
    private let simulator = PushNotificationSimulator.shared
    private var configuration: NotificationConfiguration
    
    override init() {
        self.configuration = PushNotificationSimulator.shared.configuration
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupConstraints()
    }
    
    private func setupUI() {
        title = "Settings"
        
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.rightBarButtonItem = saveButton
    }
    
    private func setupTableView() {
        tableView.register(MenuSwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
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
    
    @objc private func saveTapped() {
        DebugSwift.PushNotification.updateConfiguration(configuration)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension PushNotificationSettingsController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 // Display, Behavior, Advanced
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // Show in foreground, Play sound, Show badge
        case 1: return 2 // Auto interaction, Interaction delay
        case 2: return 2 // Max history, Simulate real push
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Display Options"
        case 1: return "Behavior"
        case 2: return "Advanced"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Control how notifications appear when the app is active"
        case 1: return "Configure automatic interaction simulation"
        case 2: return "Advanced configuration options"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return displayOptionCell(for: indexPath.row)
        case 1:
            return behaviorCell(for: indexPath.row)
        case 2:
            return advancedCell(for: indexPath.row)
        default:
            return UITableViewCell()
        }
    }
    
    private func displayOptionCell(for row: Int) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as? MenuSwitchTableViewCell else {
            return UITableViewCell()
        }
        
        switch row {
        case 0:
            cell.titleLabel.text = "Show in Foreground"
            cell.valueSwitch.isOn = configuration.showInForeground
            cell.tag = 100
        case 1:
            cell.titleLabel.text = "Play Sound"
            cell.valueSwitch.isOn = configuration.playSound
            cell.tag = 101
        case 2:
            cell.titleLabel.text = "Show Badge"
            cell.valueSwitch.isOn = configuration.showBadge
            cell.tag = 102
        default:
            break
        }
        
        cell.delegate = self
        
        return cell
    }
    
    private func behaviorCell(for row: Int) -> UITableViewCell {
        switch row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as? MenuSwitchTableViewCell else {
                return UITableViewCell()
            }
            
            cell.titleLabel.text = "Auto Interaction"
            cell.valueSwitch.isOn = configuration.autoInteraction
            cell.tag = 200
            cell.delegate = self
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
            cell.textLabel?.text = "Interaction Delay"
            cell.detailTextLabel?.text = String(format: "%.1fs", configuration.interactionDelay)
            cell.accessoryType = configuration.autoInteraction ? UITableViewCell.AccessoryType.disclosureIndicator : UITableViewCell.AccessoryType.none
            cell.selectionStyle = configuration.autoInteraction ? UITableViewCell.SelectionStyle.default : UITableViewCell.SelectionStyle.none
            cell.textLabel?.textColor = configuration.autoInteraction ? UIColor.label : UIColor.systemGray3
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    private func advancedCell(for row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
            cell.textLabel?.text = "Max History Count"
            cell.detailTextLabel?.text = "\(configuration.maxHistoryCount)"
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as? MenuSwitchTableViewCell else {
                return UITableViewCell()
            }
            
            cell.titleLabel.text = "Simulate Real Push"
            cell.valueSwitch.isOn = configuration.simulateRealPush
            cell.tag = 300
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate

extension PushNotificationSettingsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1:
            if indexPath.row == 1 && configuration.autoInteraction {
                showDelayPicker()
            }
        case 2:
            if indexPath.row == 0 {
                showHistoryCountPicker()
            }
        default:
            break
        }
    }
    
    private func showDelayPicker() {
        let alert = UIAlertController(title: "Interaction Delay", message: "How long after delivery should interaction be simulated?", preferredStyle: .actionSheet)
        
        let delays: [TimeInterval] = [1.0, 2.0, 3.0, 5.0, 10.0]
        
        for delay in delays {
            let action = UIAlertAction(title: String(format: "%.1f seconds", delay), style: .default) { [weak self] _ in
                self?.configuration.interactionDelay = delay
                self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            }
            if delay == configuration.interactionDelay {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 1, section: 1))
        }
        
        present(alert, animated: true)
    }
    
    private func showHistoryCountPicker() {
        let alert = UIAlertController(title: "History Count", message: "Maximum number of notifications to keep in history", preferredStyle: .actionSheet)
        
        let counts = [50, 100, 200, 500, 1000]
        
        for count in counts {
            let action = UIAlertAction(title: "\(count) notifications", style: .default) { [weak self] _ in
                self?.configuration.maxHistoryCount = count
                self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
            }
            if count == configuration.maxHistoryCount {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 0, section: 2))
        }
        
        present(alert, animated: true)
    }
}

// MARK: - MenuSwitchTableViewCellDelegate

extension PushNotificationSettingsController: MenuSwitchTableViewCellDelegate {
    func menuSwitchTableViewCell(_ cell: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        switch cell.tag {
        case 100: // Show in Foreground
            configuration.showInForeground = isOn
        case 101: // Play Sound
            configuration.playSound = isOn
        case 102: // Show Badge
            configuration.showBadge = isOn
        case 200: // Auto Interaction
            configuration.autoInteraction = isOn
            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
        case 300: // Simulate Real Push
            configuration.simulateRealPush = isOn
        default:
            break
        }
    }
} 