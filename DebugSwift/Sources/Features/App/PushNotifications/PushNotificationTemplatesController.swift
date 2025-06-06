//
//  PushNotificationTemplatesController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

@MainActor
class PushNotificationTemplatesController: BaseController {
    
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
        title = "Templates"
        
        let addButton = UIBarButtonItem(
            title: "Add",
            style: .plain,
            target: self,
            action: #selector(addTemplateTapped)
        )
        navigationItem.rightBarButtonItem = addButton
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
    
    @objc private func addTemplateTapped() {
        // For now, show a simple alert to add a template
        showAddTemplateAlert()
    }
}

// MARK: - UITableViewDataSource

extension PushNotificationTemplatesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return simulator.templates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let template = simulator.templates[indexPath.row]
        cell.textLabel?.text = template.name
        cell.detailTextLabel?.text = template.title
        cell.accessoryType = .disclosureIndicator
        
        // Show default template indicator
        if template.isDefault {
            cell.textLabel?.textColor = .systemBlue
        } else {
            cell.textLabel?.textColor = .label
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PushNotificationTemplatesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let template = simulator.templates[indexPath.row]
        showTemplateActionSheet(for: template, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let template = simulator.templates[indexPath.row]
        return !template.isDefault // Don't allow editing default templates
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let template = simulator.templates[indexPath.row]
            DebugSwift.PushNotification.removeTemplate(id: template.id)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    private func showTemplateActionSheet(for template: NotificationTemplate, at indexPath: IndexPath) {
        let alert = UIAlertController(title: template.name, message: template.title, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "🚀 Send Now", style: .default) { _ in
            DebugSwift.PushNotification.simulateFromTemplate(template.name)
        })
        
        alert.addAction(UIAlertAction(title: "⏰ Send in 5s", style: .default) { _ in
            DebugSwift.PushNotification.simulateFromTemplate(template.name, delay: 5.0)
        })
        
        alert.addAction(UIAlertAction(title: "📋 View Details", style: .default) { _ in
            self.showTemplateDetails(template)
        })
        
        if !template.isDefault {
            alert.addAction(UIAlertAction(title: "🗑️ Delete", style: .destructive) { _ in
                DebugSwift.PushNotification.removeTemplate(id: template.id)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        
        present(alert, animated: true)
    }
    
    private func showTemplateDetails(_ template: NotificationTemplate) {
        var details: [String] = []
        details.append("Title: \(template.title)")
        details.append("Body: \(template.body)")
        
        if let subtitle = template.subtitle, !subtitle.isEmpty {
            details.append("Subtitle: \(subtitle)")
        }
        
        if let badge = template.badge {
            details.append("Badge: \(badge)")
        }
        
        if let sound = template.sound {
            details.append("Sound: \(sound)")
        }
        
        if !template.userInfo.isEmpty {
            details.append("\nUser Info:")
            for (key, value) in template.userInfo {
                details.append("  \(key): \(value)")
            }
        }
        
        let alert = UIAlertController(title: template.name, message: details.joined(separator: "\n"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAddTemplateAlert() {
        let alert = UIAlertController(title: "Add Template", message: "Create a new notification template", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Template name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Notification title"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Notification body"
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let title = alert.textFields?[1].text, !title.isEmpty,
                  let body = alert.textFields?[2].text, !body.isEmpty else {
                return
            }
            
            let template = NotificationTemplate(
                name: name,
                title: title,
                body: body
            )
            
            DebugSwift.PushNotification.addTemplate(template)
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
} 