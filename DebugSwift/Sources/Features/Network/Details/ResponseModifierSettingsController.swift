//
//  ResponseModifierSettingsController.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 13/04/26.
//

import UIKit
import UniformTypeIdentifiers

final class ResponseModifierSettingsController: BaseTableController, UIDocumentPickerDelegate {
    private enum Section: Int, CaseIterable {
        case options
        case rules
    }

    private var rewriteConfig: ResponseBodyRewriteConfig {
        NetworkInjectionManager.shared.getRewriteConfig()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupUI() {
        title = "Response Modifier"
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addRuleTapped)
        )
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showMoreMenu)
        )
        navigationItem.rightBarButtonItems = [addButton, menuButton]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        switch sectionType {
        case .options:
            return 5
        case .rules:
            return max(rewriteConfig.rules.count, 1)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        switch sectionType {
        case .options: return "OPTIONS"
        case .rules: return "API RULES"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section), sectionType == .options else { return nil }
        return "Warning: Broad wildcard patterns (such as *) and many response modifier rules can reduce network matching performance."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        switch section {
        case .options:
            return optionCell(for: indexPath.row)
        case .rules:
            return ruleCell(for: indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .options:
            handleOptionSelection(row: indexPath.row)
        case .rules:
            guard !rewriteConfig.rules.isEmpty else { return }
            showRewriteRuleEditor(existingRule: rewriteConfig.rules[indexPath.row], editIndex: indexPath.row)
        }
    }

    private func optionCell(for row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        let config = rewriteConfig

        switch row {
        case 0:
            cell.textLabel?.text = "Enable Response Modifier"
            let toggle = UISwitch()
            toggle.isOn = config.isEnabled
            toggle.addTarget(self, action: #selector(masterToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 1:
            cell.textLabel?.text = "Auto-enable Every Run"
            let toggle = UISwitch()
            toggle.isOn = NetworkInjectionManager.shared.shouldAutoEnableRewriteOnRun()
            toggle.addTarget(self, action: #selector(autoEnableToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 2:
            cell.textLabel?.text = "Enable All Rules"
            cell.detailTextLabel?.text = enabledRuleCountSummary()
            let toggle = UISwitch()
            toggle.isOn = areAllRulesEnabled()
            toggle.addTarget(self, action: #selector(allRulesToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 3:
            cell.textLabel?.text = "Short-circuit Mode"
            let toggle = UISwitch()
            toggle.isOn = NetworkInjectionManager.shared.isRewriteShortCircuitEnabled()
            toggle.addTarget(self, action: #selector(shortCircuitToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 4:
            cell.textLabel?.text = "Import / Export CSV"
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        return cell
    }

    private func ruleCell(for row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "RuleCell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray

        let rules = rewriteConfig.rules
        guard !rules.isEmpty else {
            cell.textLabel?.text = "No Response Modifier Rules"
            cell.detailTextLabel?.text = "Tap + to add a rule"
            cell.selectionStyle = .none
            return cell
        }
        let rule = rules[row]
        let displayPattern = rule.urlPattern
        cell.textLabel?.text = displayPattern
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.lineBreakMode = .byTruncatingHead
        cell.detailTextLabel?.text = rule.httpMethod?.rawValue ?? "All Methods"
        let toggle = UISwitch()
        toggle.isOn = rule.isEnabled
        toggle.tag = row
        toggle.addTarget(self, action: #selector(ruleToggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    private func handleOptionSelection(row: Int) {
        switch row {
        case 0:
            showInfoAlert(
                title: "Enable Response Modifier",
                message: "Turns response modifier on or off globally. When off, no rewrite rules are applied."
            )
        case 1:
            showInfoAlert(
                title: "Auto-enable Every Run",
                message: "If enabled, response modifier will automatically be active each time the app starts."
            )
        case 2:
            showInfoAlert(
                title: "Enable All Rules",
                message: "Quickly enable or disable all existing rules at once."
            )
        case 3:
            showInfoAlert(
                title: "Short-circuit Matched Rules",
                message: "When enabled, matched rules return mocked responses immediately from local data. This works offline and skips the real network request for matched rules."
            )
        case 4:
            showImportExportMenu()
        default:
            break
        }
    }

    @objc private func addRuleTapped() {
        showRewriteRuleEditor()
    }

    @objc private func showMoreMenu() {
        let alert = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Reset All", style: .destructive) { [weak self] _ in
            self?.confirmResetAll()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(alert, animated: true)
    }

    private func confirmResetAll() {
        let alert = UIAlertController(
            title: "Reset All Response Modifier Settings?",
            message: "This will disable Response Modifier, disable Auto-enable, keep Short-circuit Mode enabled, and remove all rules.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Reset All", style: .destructive) { [weak self] _ in
            self?.performResetAll()
        })
        present(alert, animated: true)
    }

    private func performResetAll() {
        let resetConfig = ResponseBodyRewriteConfig(isEnabled: false, rules: [])
        NetworkInjectionManager.shared.setRewriteConfig(resetConfig)
        NetworkInjectionManager.shared.setRewriteAutoEnableOnRun(false)
        NetworkInjectionManager.shared.setRewriteShortCircuitEnabled(true)
        tableView.reloadData()
    }

    @objc private func masterToggleChanged(_ sender: UISwitch) {
        var config = rewriteConfig
        config.isEnabled = sender.isOn
        NetworkInjectionManager.shared.setRewriteConfig(config)
    }

    @objc private func autoEnableToggleChanged(_ sender: UISwitch) {
        NetworkInjectionManager.shared.setRewriteAutoEnableOnRun(sender.isOn)
    }
    
    @objc private func shortCircuitToggleChanged(_ sender: UISwitch) {
        NetworkInjectionManager.shared.setRewriteShortCircuitEnabled(sender.isOn)
    }
    
    private func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func ruleToggleChanged(_ sender: UISwitch) {
        var config = rewriteConfig
        guard config.rules.indices.contains(sender.tag) else { return }
        config.rules[sender.tag].isEnabled = sender.isOn
        NetworkInjectionManager.shared.setRewriteConfig(config)
        tableView.reloadData()
    }

    private func updateRewriteRules(_ rules: [ResponseBodyRewriteRule]) {
        var config = rewriteConfig
        config.rules = rules
        NetworkInjectionManager.shared.setRewriteConfig(config)
    }

    private func enabledRuleCountSummary() -> String {
        let rules = rewriteConfig.rules
        let enabledCount = rules.filter(\.isEnabled).count
        return "\(enabledCount)/\(rules.count)"
    }

    private func areAllRulesEnabled() -> Bool {
        let rules = rewriteConfig.rules
        return !rules.isEmpty && rules.allSatisfy(\.isEnabled)
    }

    @objc private func allRulesToggleChanged(_ sender: UISwitch) {
        setAllRulesEnabled(sender.isOn)
    }

    private func setAllRulesEnabled(_ isEnabled: Bool) {
        let loading = UIAlertController(title: nil, message: "Updating rules...", preferredStyle: .alert)
        present(loading, animated: true)

        var config = rewriteConfig
        config.rules = config.rules.map {
            var rule = $0
            rule.isEnabled = isEnabled
            return rule
        }
        NetworkInjectionManager.shared.setRewriteConfig(config)
        DispatchQueue.main.async { [weak self] in
            loading.dismiss(animated: true) {
                self?.tableView.reloadData()
            }
        }
    }

    private func showImportExportMenu() {
        let alert = UIAlertController(title: "Response Modifier CSV", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Export CSV", style: .default) { [weak self] _ in
            self?.exportRewriteRulesCSV()
        })
        alert.addAction(UIAlertAction(title: "Import CSV", style: .default) { [weak self] _ in
            self?.importRewriteRulesCSV()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showRewriteRuleEditor(existingRule: ResponseBodyRewriteRule? = nil, editIndex: Int? = nil) {
        let editor = RewriteRuleEditViewController(rule: existingRule) { [weak self] updatedRule in
            guard let self = self else { return }
            var updatedRules = self.rewriteConfig.rules
            if let editIndex {
                updatedRules[editIndex] = updatedRule
            } else if let existingIndex = updatedRules.firstIndex(where: { $0.urlPattern == updatedRule.urlPattern && $0.httpMethod == updatedRule.httpMethod }) {
                updatedRules[existingIndex] = updatedRule
            } else {
                updatedRules.append(updatedRule)
            }
            self.updateRewriteRules(updatedRules)
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard Section(rawValue: indexPath.section) == .rules, !rewriteConfig.rules.isEmpty else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            var updatedRules = self.rewriteConfig.rules
            updatedRules.remove(at: indexPath.row)
            self.updateRewriteRules(updatedRules)
            self.tableView.reloadData()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func exportRewriteRulesCSV() {
        let csv = RewriteRulesCSV.export(rules: rewriteConfig.rules)
        guard let data = csv.data(using: .utf8) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "response_modifier_rules_\(formatter.string(from: Date())).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            showMessageAlert(title: "Export Error", message: error.localizedDescription)
            return
        }

        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 1, width: 1, height: 1)
        }
        present(activityVC, animated: true)
    }

    private func importRewriteRulesCSV() {
        if #available(iOS 14.0, *) {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText, .plainText])
            picker.delegate = self
            picker.allowsMultipleSelection = false
            present(picker, animated: true)
        } else {
            let picker = UIDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text", "public.plain-text"], in: .import)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            present(picker, animated: true)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        let hasAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: fileURL)
            guard let csvText = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "DebugSwift.NetworkInjection", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV file must be UTF-8 encoded."])
            }
            let importedRules = try RewriteRulesCSV.parse(csvText)
            let merged = applyImportedRewriteRules(importedRules)
            showMessageAlert(title: "Import Complete", message: "Created \(merged.created) rule(s), updated \(merged.updated) rule(s).")
        } catch {
            showMessageAlert(title: "Import Error", message: error.localizedDescription)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}

    private func applyImportedRewriteRules(_ importedRules: [ResponseBodyRewriteRule]) -> (created: Int, updated: Int) {
        var mergedRules = rewriteConfig.rules
        var created = 0
        var updated = 0
        for importedRule in importedRules {
            if let existingIndex = mergedRules.firstIndex(where: { $0.urlPattern == importedRule.urlPattern && $0.httpMethod == importedRule.httpMethod }) {
                mergedRules[existingIndex].responseBody = importedRule.responseBody
                mergedRules[existingIndex].responseStatusCode = importedRule.responseStatusCode
                mergedRules[existingIndex].httpMethod = importedRule.httpMethod
                updated += 1
            } else {
                mergedRules.append(importedRule)
                created += 1
            }
        }
        updateRewriteRules(mergedRules)
        tableView.reloadData()
        return (created, updated)
    }

    private func showMessageAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
