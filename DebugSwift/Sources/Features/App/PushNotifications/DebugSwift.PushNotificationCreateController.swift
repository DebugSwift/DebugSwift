//
//  PushNotificationCreateController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

@MainActor
class PushNotificationCreateController: BaseController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        return tableView
    }()
    
    private struct NotificationForm {
        var title: String = ""
        var body: String = ""
        var subtitle: String = ""
        var badge: String = ""
        var sound: String = "default"
        var delay: String = "0"
        var userInfo: [(key: String, value: String)] = []
    }
    
    private var form = NotificationForm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupConstraints()
    }
    
    private func setupUI() {
        title = "Create Notification"
        
        let sendButton = UIBarButtonItem(
            title: "Send",
            style: .done,
            target: self,
            action: #selector(sendNotification)
        )
        navigationItem.rightBarButtonItem = sendButton
        
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    private func setupTableView() {
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
    
    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sendNotification() {
        guard !form.title.isEmpty && !form.body.isEmpty else {
            showAlert(title: "Error", message: "Title and body are required")
            return
        }
        
        let badge = Int(form.badge.isEmpty ? "0" : form.badge)
        let delay = Double(form.delay.isEmpty ? "0" : form.delay) ?? 0
        
        var userInfo: [String: String] = [:]
        for item in form.userInfo {
            if !item.key.isEmpty && !item.value.isEmpty {
                userInfo[item.key] = item.value
            }
        }
        
        DebugSwift.PushNotification.simulate(
            title: form.title,
            body: form.body,
            subtitle: form.subtitle.isEmpty ? nil : form.subtitle,
            badge: badge,
            sound: form.sound == "none" ? nil : form.sound,
            userInfo: userInfo,
            delay: delay
        )
        
        navigationController?.popViewController(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension PushNotificationCreateController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 // Basic Info, Advanced, User Info
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // Title, Body, Subtitle, Badge
        case 1: return 2 // Sound, Delay
        case 2: return form.userInfo.count + 1 // User Info + Add button
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Basic Information"
        case 1: return "Advanced Options"
        case 2: return "User Info (Key-Value Pairs)"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return basicInfoCell(for: indexPath.row)
        case 1:
            return advancedCell(for: indexPath.row)
        case 2:
            return userInfoCell(for: indexPath.row)
        default:
            return UITableViewCell()
        }
    }
    
    private func basicInfoCell(for row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        
        switch row {
        case 0:
            cell.textLabel?.text = "Title *"
            cell.detailTextLabel?.text = form.title.isEmpty ? "Notification title" : form.title
        case 1:
            cell.textLabel?.text = "Body *"
            cell.detailTextLabel?.text = form.body.isEmpty ? "Notification body" : form.body
        case 2:
            cell.textLabel?.text = "Subtitle"
            cell.detailTextLabel?.text = form.subtitle.isEmpty ? "Optional subtitle" : form.subtitle
        case 3:
            cell.textLabel?.text = "Badge"
            cell.detailTextLabel?.text = form.badge.isEmpty ? "Badge number" : form.badge
        default:
            break
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    private func advancedCell(for row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
            cell.textLabel?.text = "Sound"
            cell.detailTextLabel?.text = form.sound
            cell.accessoryType = .disclosureIndicator
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .value1, reuseIdentifier: "Cell")
            cell.textLabel?.text = "Delay (seconds)"
            cell.detailTextLabel?.text = form.delay.isEmpty ? "0" : form.delay
            cell.accessoryType = .disclosureIndicator
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    private func userInfoCell(for row: Int) -> UITableViewCell {
        if row < form.userInfo.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
            let item = form.userInfo[row]
            cell.textLabel?.text = item.key
            cell.detailTextLabel?.text = item.value
            cell.accessoryType = .disclosureIndicator
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
            cell.textLabel?.text = "➕ Add User Info"
            cell.textLabel?.textColor = .systemBlue
            cell.accessoryType = .none
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension PushNotificationCreateController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            showTextInputAlert(for: indexPath.row)
        case 1:
            if indexPath.row == 0 {
                showSoundPicker()
            } else {
                showDelayInputAlert()
            }
        case 2:
            if indexPath.row < form.userInfo.count {
                editUserInfo(at: indexPath.row)
            } else {
                addUserInfo()
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 2 && indexPath.row < form.userInfo.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == 2 && indexPath.row < form.userInfo.count {
            form.userInfo.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    private func showSoundPicker() {
        let alert = UIAlertController(title: "Sound", message: "Choose notification sound", preferredStyle: .actionSheet)
        
        let sounds = ["default", "none", "alert", "glass", "horn", "bell"]
        
        for sound in sounds {
            let action = UIAlertAction(title: sound.capitalized, style: .default) { [weak self] _ in
                self?.form.sound = sound
                self?.tableView.reloadData()
            }
            if sound == form.sound {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 0, section: 1))
        }
        
        present(alert, animated: true)
    }
    
    private func addUserInfo() {
        showUserInfoAlert(title: "Add User Info", key: "", value: "") { [weak self] key, value in
            self?.form.userInfo.append((key: key, value: value))
            self?.tableView.reloadSections([2], with: .automatic)
        }
    }
    
    private func editUserInfo(at index: Int) {
        let item = form.userInfo[index]
        showUserInfoAlert(title: "Edit User Info", key: item.key, value: item.value) { [weak self] key, value in
            self?.form.userInfo[index] = (key: key, value: value)
            self?.tableView.reloadSections([2], with: .automatic)
        }
    }
    
    private func showUserInfoAlert(title: String, key: String, value: String, completion: @escaping (String, String) -> Void) {
        let alert = UIAlertController(title: title, message: "Enter key-value pair", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Key"
            textField.text = key
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Value"
            textField.text = value
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let key = alert.textFields?[0].text ?? ""
            let value = alert.textFields?[1].text ?? ""
            
            guard !key.isEmpty && !value.isEmpty else {
                return
            }
            
            completion(key, value)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showTextInputAlert(for row: Int) {
        var title = ""
        var placeholder = ""
        var currentValue = ""
        
        switch row {
        case 0:
            title = "Title"
            placeholder = "Notification title"
            currentValue = form.title
        case 1:
            title = "Body"
            placeholder = "Notification body"
            currentValue = form.body
        case 2:
            title = "Subtitle"
            placeholder = "Optional subtitle"
            currentValue = form.subtitle
        case 3:
            title = "Badge"
            placeholder = "Badge number"
            currentValue = form.badge
        default:
            return
        }
        
        let alert = UIAlertController(title: "Edit \(title)", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = currentValue
            if row == 3 {
                textField.keyboardType = UIKeyboardType.numberPad
            }
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let text = alert.textFields?[0].text ?? ""
            
            switch row {
            case 0: self?.form.title = text
            case 1: self?.form.body = text
            case 2: self?.form.subtitle = text
            case 3: self?.form.badge = text
            default: break
            }
            
            self?.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showDelayInputAlert() {
        let alert = UIAlertController(title: "Delay (seconds)", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "0"
            textField.text = self.form.delay
            textField.keyboardType = UIKeyboardType.decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let text = alert.textFields?[0].text ?? ""
            self?.form.delay = text
            self?.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
} 