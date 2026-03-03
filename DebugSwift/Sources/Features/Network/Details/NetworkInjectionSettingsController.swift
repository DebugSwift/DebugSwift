//
//  NetworkInjectionSettingsController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import UIKit

final class NetworkInjectionSettingsController: BaseTableController {
    
    // MARK: - Sections
    
    private enum Section: Int, CaseIterable {
        case delay
        case failure
        case rewrite
        
        var title: String {
            switch self {
            case .delay: return "REQUEST DELAY INJECTION"
            case .failure: return "NETWORK FAILURE INJECTION"
            case .rewrite: return "RESPONSE BODY REWRITE"
            }
        }
    }
    
    // MARK: - Properties
    
    private var delayConfig: RequestDelayConfig
    private var failureConfig: NetworkFailureConfig
    private var rewriteConfig: ResponseBodyRewriteConfig
    
    // MARK: - Initialization
    
    override init() {
        self.delayConfig = NetworkInjectionManager.shared.getDelayConfig()
        self.failureConfig = NetworkInjectionManager.shared.getFailureConfig()
        self.rewriteConfig = NetworkInjectionManager.shared.getRewriteConfig()
        super.init()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Network Injection"
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        
        // Add apply button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Apply",
            style: .done,
            target: self,
            action: #selector(saveSettings)
        )
    }
    
    @objc private func saveSettings() {
        NetworkInjectionManager.shared.setDelayConfig(delayConfig)
        NetworkInjectionManager.shared.setFailureConfig(failureConfig)
        NetworkInjectionManager.shared.setRewriteConfig(rewriteConfig)
        
        let alert = UIAlertController(
            title: "Settings Applied",
            message: "Network injection settings have been updated",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .delay:
            return delayConfig.isEnabled ? 5 : 1
        case .failure:
            return failureConfig.isEnabled ? (failureConfig.failureType.isHTTPError ? 6 : 5) : 1
        case .rewrite:
            return rewriteConfig.isEnabled ? 3 : 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .delay:
            return delayCell(for: indexPath.row)
        case .failure:
            return failureCell(for: indexPath.row)
        case .rewrite:
            return rewriteCell(for: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .delay:
            handleDelaySelection(row: indexPath.row)
        case .failure:
            handleFailureSelection(row: indexPath.row)
        case .rewrite:
            handleRewriteSelection(row: indexPath.row)
        }
    }
    
    // MARK: - Delay Cells
    
    private func delayCell(for row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        
        switch row {
        case 0:
            cell.textLabel?.text = "Enable Delay"
            let toggle = UISwitch()
            toggle.isOn = delayConfig.isEnabled
            toggle.addTarget(self, action: #selector(delayToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 1:
            cell.textLabel?.text = "Delay Type"
            cell.detailTextLabel?.text = delayConfig.fixedDelay != nil ? "Fixed" : "Random"
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.textLabel?.text = "Delay Value"
            if let fixed = delayConfig.fixedDelay {
                cell.detailTextLabel?.text = String(format: "%.1fs", fixed)
            } else {
                cell.detailTextLabel?.text = String(format: "%.1f-%.1fs", delayConfig.minDelay, delayConfig.maxDelay)
            }
            cell.accessoryType = .disclosureIndicator
        case 3:
            cell.textLabel?.text = "URL Patterns"
            cell.detailTextLabel?.text = delayConfig.urlPatterns.isEmpty ? "All" : "\(delayConfig.urlPatterns.count)"
            cell.accessoryType = .disclosureIndicator
        case 4:
            cell.textLabel?.text = "HTTP Methods"
            cell.detailTextLabel?.text = delayConfig.httpMethods.isEmpty ? "All" : "\(delayConfig.httpMethods.count)"
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        
        return cell
    }
    
    // MARK: - Failure Cells
    
    private func failureCell(for row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        
        switch row {
        case 0:
            cell.textLabel?.text = "Enable Failure"
            let toggle = UISwitch()
            toggle.isOn = failureConfig.isEnabled
            toggle.addTarget(self, action: #selector(failureToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 1:
            cell.textLabel?.text = "Failure Rate"
            cell.detailTextLabel?.text = String(format: "%.0f%%", failureConfig.failureRate * 100)
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.textLabel?.text = "Failure Type"
            cell.detailTextLabel?.text = failureTypeDescription(failureConfig.failureType)
            cell.accessoryType = .disclosureIndicator
        case 3:
            if failureConfig.failureType.isHTTPError {
                cell.textLabel?.text = "HTTP Status Codes"
                cell.detailTextLabel?.text = failureConfig.customStatusCodes.map { String($0) }.joined(separator: ",")
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "URL Patterns"
                cell.detailTextLabel?.text = failureConfig.urlPatterns.isEmpty ? "All" : "\(failureConfig.urlPatterns.count)"
                cell.accessoryType = .disclosureIndicator
            }
        case 4:
            if failureConfig.failureType.isHTTPError {
                cell.textLabel?.text = "URL Patterns"
                cell.detailTextLabel?.text = failureConfig.urlPatterns.isEmpty ? "All" : "\(failureConfig.urlPatterns.count)"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "HTTP Methods"
                cell.detailTextLabel?.text = failureConfig.httpMethods.isEmpty ? "All" : "\(failureConfig.httpMethods.count)"
                cell.accessoryType = .disclosureIndicator
            }
        case 5:
            cell.textLabel?.text = "HTTP Methods"
            cell.detailTextLabel?.text = failureConfig.httpMethods.isEmpty ? "All" : "\(failureConfig.httpMethods.count)"
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        
        return cell
    }
    
    // MARK: - Rewrite Cells
    
    private func rewriteCell(for row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        
        switch row {
        case 0:
            cell.textLabel?.text = "Enable Rewrite"
            let toggle = UISwitch()
            toggle.isOn = rewriteConfig.isEnabled
            toggle.addTarget(self, action: #selector(rewriteToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 1:
            cell.textLabel?.text = "Rewrite Rules"
            cell.detailTextLabel?.text = rewriteConfig.rules.isEmpty ? "None" : "\(rewriteConfig.rules.count)"
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.textLabel?.text = "Rule Priority"
            cell.detailTextLabel?.text = "First Match Wins"
            cell.selectionStyle = .none
        default:
            break
        }
        
        return cell
    }
    
    // MARK: - Actions
    
    @objc private func delayToggled(_ sender: UISwitch) {
        delayConfig.isEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: Section.delay.rawValue), with: .automatic)
    }
    
    @objc private func failureToggled(_ sender: UISwitch) {
        failureConfig.isEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: Section.failure.rawValue), with: .automatic)
    }
    
    @objc private func rewriteToggled(_ sender: UISwitch) {
        rewriteConfig.isEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: Section.rewrite.rawValue), with: .automatic)
    }
    
    private func updateRewriteRules() {
        var persistedConfig = NetworkInjectionManager.shared.getRewriteConfig()
        persistedConfig.rules = rewriteConfig.rules
        NetworkInjectionManager.shared.setRewriteConfig(persistedConfig)
    }
    
    private func handleDelaySelection(row: Int) {
        switch row {
        case 1: showDelayTypeOptions()
        case 2: showDelayValueInput()
        case 3: showURLPatternsInput(for: .delay)
        case 4: showHTTPMethodsInput(for: .delay)
        default: break
        }
    }
    
    private func handleFailureSelection(row: Int) {
        if failureConfig.failureType.isHTTPError {
            switch row {
            case 1: showFailureRateInput()
            case 2: showFailureTypeOptions()
            case 3: showHTTPStatusCodesInput()
            case 4: showURLPatternsInput(for: .failure)
            case 5: showHTTPMethodsInput(for: .failure)
            default: break
            }
        } else {
            switch row {
            case 1: showFailureRateInput()
            case 2: showFailureTypeOptions()
            case 3: showURLPatternsInput(for: .failure)
            case 4: showHTTPMethodsInput(for: .failure)
            default: break
            }
        }
    }
    
    private func handleRewriteSelection(row: Int) {
        switch row {
        case 1:
            showRewriteRulesMenu()
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func failureTypeDescription(_ type: NetworkFailureConfig.FailureType) -> String {
        switch type {
        case .timeout: return "Timeout"
        case .connectionLost: return "Connection Lost"
        case .notConnectedToInternet: return "No Internet"
        case .cannotFindHost: return "Cannot Find Host"
        case .dnsLookupFailed: return "DNS Lookup Failed"
        case .httpError: return "HTTP Error"
        case .sslError: return "SSL Error"
        case .cancelled: return "Cancelled"
        case .custom: return "Custom Error"
        }
    }
    
    enum InjectionType {
        case delay
        case failure
    }
    
    // MARK: - Input Dialogs
    
    private func showDelayTypeOptions() {
        let alert = UIAlertController(title: "Delay Type", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Fixed Delay", style: .default) { [weak self] _ in
            self?.delayConfig.fixedDelay = 2.0
            self?.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Random Range", style: .default) { [weak self] _ in
            self?.delayConfig.fixedDelay = nil
            self?.delayConfig.minDelay = 1.0
            self?.delayConfig.maxDelay = 3.0
            self?.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showDelayValueInput() {
        let alert = UIAlertController(
            title: delayConfig.fixedDelay != nil ? "Fixed Delay" : "Delay Range",
            message: "Enter delay in seconds",
            preferredStyle: .alert
        )
        
        if delayConfig.fixedDelay != nil {
            alert.addTextField { $0.keyboardType = .decimalPad; $0.placeholder = "2.0" }
        } else {
            alert.addTextField { $0.keyboardType = .decimalPad; $0.placeholder = "Min (1.0)" }
            alert.addTextField { $0.keyboardType = .decimalPad; $0.placeholder = "Max (3.0)" }
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            if self.delayConfig.fixedDelay != nil {
                if let text = alert.textFields?.first?.text, let value = Double(text) {
                    self.delayConfig.fixedDelay = value
                }
            } else {
                if let minText = alert.textFields?[0].text,
                   let maxText = alert.textFields?[1].text,
                   let min = Double(minText),
                   let max = Double(maxText) {
                    self.delayConfig.minDelay = min
                    self.delayConfig.maxDelay = max
                }
            }
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showFailureRateInput() {
        let alert = UIAlertController(title: "Failure Rate", message: "Enter percentage (0-100)", preferredStyle: .alert)
        alert.addTextField { $0.keyboardType = .numberPad; $0.placeholder = "50" }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let text = alert.textFields?.first?.text, let value = Double(text) {
                self?.failureConfig.failureRate = min(max(value / 100.0, 0), 1)
                self?.tableView.reloadData()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showFailureTypeOptions() {
        let alert = UIAlertController(title: "Failure Type", message: nil, preferredStyle: .actionSheet)
        
        let types: [(String, NetworkFailureConfig.FailureType)] = [
            ("Timeout", .timeout),
            ("Connection Lost", .connectionLost),
            ("No Internet", .notConnectedToInternet),
            ("Cannot Find Host", .cannotFindHost),
            ("DNS Lookup Failed", .dnsLookupFailed),
            ("HTTP Error", .httpError(statusCode: nil)),
            ("SSL Error", .sslError),
            ("Cancelled", .cancelled)
        ]
        
        for (title, type) in types {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.failureConfig.failureType = type
                self?.tableView.reloadData()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showHTTPStatusCodesInput() {
        let alert = UIAlertController(title: "HTTP Status Codes", message: "Comma-separated (e.g. 404,500)", preferredStyle: .alert)
        alert.addTextField { $0.keyboardType = .numbersAndPunctuation; $0.placeholder = "404, 500, 503" }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let text = alert.textFields?.first?.text {
                let codes = text.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                if !codes.isEmpty {
                    self?.failureConfig.customStatusCodes = codes
                    self?.tableView.reloadData()
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showURLPatternsInput(for type: InjectionType) {
        let patterns = type == .delay ? delayConfig.urlPatterns : failureConfig.urlPatterns
        
        let alert = UIAlertController(title: "URL Patterns", message: "Comma-separated patterns", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "api.example.com, */auth/*"; $0.text = patterns.joined(separator: ", ") }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text ?? ""
            let newPatterns = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            
            if type == .delay {
                self?.delayConfig.urlPatterns = newPatterns
            } else {
                self?.failureConfig.urlPatterns = newPatterns
            }
            self?.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showHTTPMethodsInput(for type: InjectionType) {
        let methods = type == .delay ? delayConfig.httpMethods : failureConfig.httpMethods
        
        let alert = UIAlertController(title: "HTTP Methods", message: "Select methods", preferredStyle: .actionSheet)
        
        let allMethods = ["GET", "POST", "PUT", "DELETE", "PATCH"]
        for method in allMethods {
            let isSelected = methods.contains(method)
            let title = isSelected ? "✓ \(method)" : method
            
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }
                var newMethods = methods
                if let index = newMethods.firstIndex(of: method) {
                    newMethods.remove(at: index)
                } else {
                    newMethods.append(method)
                }
                
                if type == .delay {
                    self.delayConfig.httpMethods = newMethods
                } else {
                    self.failureConfig.httpMethods = newMethods
                }
                self.showHTTPMethodsInput(for: type)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel) { [weak self] _ in
            self?.tableView.reloadData()
        })
        
        present(alert, animated: true)
    }
    
    private func showRewriteRulesMenu() {
        let alert = UIAlertController(title: "Rewrite Rules", message: "Each rule has URL wildcard + replacement body", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Add Rule", style: .default) { [weak self] _ in
            self?.showRewriteRuleEditor()
        })
        
        if !rewriteConfig.rules.isEmpty {
            alert.addAction(UIAlertAction(title: "Edit Rule", style: .default) { [weak self] _ in
                self?.showRewriteRulePicker(mode: .edit)
            })
            
            alert.addAction(UIAlertAction(title: "Delete Rule", style: .destructive) { [weak self] _ in
                self?.showRewriteRulePicker(mode: .delete)
            })
            
            alert.addAction(UIAlertAction(title: "Clear All Rules", style: .destructive) { [weak self] _ in
                self?.rewriteConfig.rules.removeAll()
                self?.updateRewriteRules()
                self?.tableView.reloadSections(IndexSet(integer: Section.rewrite.rawValue), with: .automatic)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private enum RewriteRulePickerMode {
        case edit
        case delete
    }
    
    private func showRewriteRulePicker(mode: RewriteRulePickerMode) {
        let title = mode == .edit ? "Edit Rule" : "Delete Rule"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for (index, rule) in rewriteConfig.rules.enumerated() {
            alert.addAction(UIAlertAction(title: "\(index + 1). \(rule.urlPattern)", style: .default) { [weak self] _ in
                guard let self = self else { return }
                switch mode {
                case .edit:
                    self.showRewriteRuleEditor(existingRule: rule, editIndex: index)
                case .delete:
                    self.rewriteConfig.rules.remove(at: index)
                    self.updateRewriteRules()
                    self.tableView.reloadSections(IndexSet(integer: Section.rewrite.rawValue), with: .automatic)
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showRewriteRuleEditor(existingRule: ResponseBodyRewriteRule? = nil, editIndex: Int? = nil) {
        let backItem = UIBarButtonItem()
        backItem.title = "Network Injection"
        navigationItem.backBarButtonItem = backItem
        navigationItem.backButtonDisplayMode = .default
        let editor = RewriteRuleEditViewController(rule: existingRule) { [weak self] updatedRule in
            guard let self = self else { return }
            if let editIndex {
                self.rewriteConfig.rules[editIndex] = updatedRule
            } else {
                self.rewriteConfig.rules.append(updatedRule)
            }
            self.updateRewriteRules()
            self.tableView.reloadSections(IndexSet(integer: Section.rewrite.rawValue), with: .automatic)
        }
        navigationController?.pushViewController(editor, animated: true)
    }
}

// MARK: - FailureType Extension

extension NetworkFailureConfig.FailureType {
    var isHTTPError: Bool {
        if case .httpError = self { return true }
        return false
    }
}
