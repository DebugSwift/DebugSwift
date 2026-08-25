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
        case rules
        case preferences
        case data
        case apiRules
    }

    private var rewriteConfig: ResponseBodyRewriteConfig {
        NetworkInjectionManager.shared.getRewriteConfig()
    }

    private let searchController = UISearchController(searchResultsController: nil)
    private var searchText: String = ""
    private var heroHeaderView: HeroHeaderView?

    private var isSearching: Bool {
        return searchController.isActive
    }

    private var filteredRules: [ResponseBodyRewriteRule] {
        let rules = rewriteConfig.rules
        guard !searchText.isEmpty else { return rules }
        return rules.filter { rule in
            let patternMatch = rule.urlPattern.localizedCaseInsensitiveContains(searchText)
            let methodMatch = rule.httpMethod?.rawValue.localizedCaseInsensitiveContains(searchText) == true
            return patternMatch || methodMatch
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableHeader()
        setupSearchController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateHeaderView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderViewHeight()
    }

    private func setupUI() {
        title = "Response Modifier"
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.register(SettingCell.self, forCellReuseIdentifier: "SettingCell")
        
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

    private func setupTableHeader() {
        let header = HeroHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 120))
        header.onMasterToggleChanged = { [weak self] isEnabled in
            guard let self = self else { return }
            var config = self.rewriteConfig
            config.isEnabled = isEnabled
            NetworkInjectionManager.shared.setRewriteConfig(config)
            self.updateHeaderView()
        }
        self.heroHeaderView = header
        tableView.tableHeaderView = header
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search API Rules..."
        searchController.searchBar.searchTextField.textColor = .white
        searchController.searchBar.barStyle = .black
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func updateHeaderView() {
        if isSearching {
            tableView.tableHeaderView = nil
        } else {
            guard let header = heroHeaderView else { return }
            header.configure(isEnabled: rewriteConfig.isEnabled)
            tableView.tableHeaderView = header
            updateHeaderViewHeight()
        }
    }

    private func updateHeaderViewHeight() {
        guard !isSearching, let headerView = tableView.tableHeaderView as? HeroHeaderView else { return }
        headerView.frame.size.width = tableView.bounds.width
        
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = headerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return max(filteredRules.count, 1)
        }
        guard let sectionType = Section(rawValue: section) else { return 0 }
        switch sectionType {
        case .rules:
            return 3
        case .preferences:
            return 1
        case .data:
            return 1
        case .apiRules:
            return max(rewriteConfig.rules.count, 1)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearching {
            return "API RULES"
        }
        guard let sectionType = Section(rawValue: section) else { return nil }
        switch sectionType {
        case .rules: return "RULES"
        case .preferences: return "PREFERENCES"
        case .data: return "DATA"
        case .apiRules: return "API RULES"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if isSearching { return nil }
        guard let sectionType = Section(rawValue: section), sectionType == .rules else { return nil }
        return "Warning: Broad wildcard patterns (such as *) and many response modifier rules can reduce network matching performance."
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSearching {
            return section == Section.apiRules.rawValue ? UITableView.automaticDimension : CGFloat.leastNormalMagnitude
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if isSearching {
            return CGFloat.leastNormalMagnitude
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching {
            return apiRuleCell(for: indexPath.row)
        }
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .rules, .preferences, .data:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as? SettingCell else {
                return UITableViewCell()
            }
            if section == .rules {
                if indexPath.row == 0 {
                    let toggle = UISwitch()
                    toggle.isOn = areAllRulesEnabled()
                    toggle.isEnabled = !rewriteConfig.rules.isEmpty
                    toggle.addTarget(self, action: #selector(allRulesToggleChanged(_:)), for: .valueChanged)
                    cell.configure(
                        title: "Enable All Rules",
                        iconName: "slider.horizontal.3",
                        iconBgColor: .systemPurple,
                        detailText: enabledRuleCountSummary(),
                        accessoryView: toggle
                    )
                } else if indexPath.row == 1 {
                    let toggle = UISwitch()
                    toggle.isOn = NetworkInjectionManager.shared.isRewriteShortCircuitEnabled()
                    toggle.addTarget(self, action: #selector(shortCircuitToggleChanged(_:)), for: .valueChanged)
                    cell.configure(
                        title: "Short-circuit Mode",
                        iconName: "bolt.fill",
                        iconBgColor: .systemOrange,
                        accessoryView: toggle
                    )
                } else {
                    let toggle = UISwitch()
                    toggle.isOn = NetworkInjectionManager.shared.isRewriteMultipleMatchEnabled()
                    toggle.addTarget(self, action: #selector(multipleMatchToggleChanged(_:)), for: .valueChanged)
                    cell.configure(
                        title: "Enable Multiple Match",
                        iconName: "doc.on.doc.fill",
                        iconBgColor: .systemBlue,
                        accessoryView: toggle
                    )
                }
            } else if section == .preferences {
                let toggle = UISwitch()
                toggle.isOn = NetworkInjectionManager.shared.shouldAutoEnableRewriteOnRun()
                toggle.addTarget(self, action: #selector(autoEnableToggleChanged(_:)), for: .valueChanged)
                cell.configure(
                    title: "Auto-enable Every Run",
                    iconName: "gearshape.fill",
                    iconBgColor: UIColor(red: 0.15, green: 0.35, blue: 0.6, alpha: 1.0),
                    accessoryView: toggle
                )
            } else {
                cell.configure(
                    title: "Import / Export CSV",
                    iconName: "arrow.down.doc.fill",
                    iconBgColor: .systemTeal
                )
            }
            return cell
            
        case .apiRules:
            return apiRuleCell(for: indexPath.row)
        }
    }

    private func apiRuleCell(for row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "RuleCell")
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray

        let rules = filteredRules
        guard !rules.isEmpty else {
            if !searchText.isEmpty {
                cell.textLabel?.text = "No Rules Found"
                cell.detailTextLabel?.text = "No rules match \"\(searchText)\""
            } else {
                cell.textLabel?.text = "No Response Modifier Rules"
                cell.detailTextLabel?.text = "Tap + to add a rule"
            }
            cell.selectionStyle = .none
            cell.accessoryView = nil
            return cell
        }
        let rule = rules[row]
        let displayPattern = rule.urlPattern
        cell.textLabel?.text = displayPattern
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.lineBreakMode = .byTruncatingHead
        
        let method = rule.httpMethod?.rawValue ?? "All Methods"
        if let statusCode = rule.responseStatusCode {
            cell.detailTextLabel?.text = "\(method) • \(statusCode)"
        } else {
            cell.detailTextLabel?.text = method
        }
        
        let toggle = UISwitch()
        toggle.isOn = rule.isEnabled
        toggle.tag = row
        toggle.addTarget(self, action: #selector(ruleToggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        cell.selectionStyle = .default
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isSearching {
            selectApiRule(at: indexPath.row)
            return
        }
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .rules:
            if indexPath.row == 0 {
                showInfoAlert(
                    title: "Enable All Rules",
                    message: "Quickly enable or disable all existing rules at once."
                )
            } else if indexPath.row == 1 {
                showInfoAlert(
                    title: "Short-circuit Matched Rules",
                    message: "When enabled, matched rules return mocked responses immediately from local data. This works offline and skips the real network request for matched rules."
                )
            } else {
                showInfoAlert(
                    title: "Multiple Match Selection",
                    message: "When enabled, if a request matches more than one rule, you can choose which rule to apply. Default is first-match behavior when disabled."
                )
            }
        case .preferences:
            showInfoAlert(
                title: "Auto-enable Every Run",
                message: "If enabled, response modifier will automatically be active each time the app starts."
            )
        case .data:
            showImportExportMenu()
        case .apiRules:
            selectApiRule(at: indexPath.row)
        }
    }

    private func selectApiRule(at row: Int) {
        guard !filteredRules.isEmpty else { return }
        let ruleToEdit = filteredRules[row]
        if let index = rewriteConfig.rules.firstIndex(where: { $0.urlPattern == ruleToEdit.urlPattern && $0.httpMethod == ruleToEdit.httpMethod }) {
            showRewriteRuleEditor(existingRule: ruleToEdit, editIndex: index)
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
            message: "This will disable Response Modifier, disable Auto-enable, disable Multiple Match, keep Short-circuit Mode enabled, and remove all rules.",
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
        NetworkInjectionManager.shared.setRewriteMultipleMatchEnabled(false)
        NetworkInjectionManager.shared.setRewriteShortCircuitEnabled(true)
        tableView.reloadData()
        updateHeaderView()
    }

    @objc private func autoEnableToggleChanged(_ sender: UISwitch) {
        NetworkInjectionManager.shared.setRewriteAutoEnableOnRun(sender.isOn)
    }
    
    @objc private func shortCircuitToggleChanged(_ sender: UISwitch) {
        NetworkInjectionManager.shared.setRewriteShortCircuitEnabled(sender.isOn)
    }

    @objc private func multipleMatchToggleChanged(_ sender: UISwitch) {
        NetworkInjectionManager.shared.setRewriteMultipleMatchEnabled(sender.isOn)
    }
    
    private func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func ruleToggleChanged(_ sender: UISwitch) {
        let rules = filteredRules
        guard rules.indices.contains(sender.tag) else { return }
        let rule = rules[sender.tag]
        
        var config = rewriteConfig
        if let index = config.rules.firstIndex(where: { $0.urlPattern == rule.urlPattern && $0.httpMethod == rule.httpMethod }) {
            config.rules[index].isEnabled = sender.isOn
            NetworkInjectionManager.shared.setRewriteConfig(config)
            updateHeaderView()
        }
    }

    private func updateRewriteRules(_ rules: [ResponseBodyRewriteRule]) {
        var config = rewriteConfig
        config.rules = rules
        NetworkInjectionManager.shared.setRewriteConfig(config)
        updateHeaderView()
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
                self?.updateHeaderView()
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
            self.updateHeaderView()
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isSearching || Section(rawValue: indexPath.section) == .apiRules else { return nil }
        return deleteSwipeAction(for: indexPath.row)
    }

    private func deleteSwipeAction(for row: Int) -> UISwipeActionsConfiguration? {
        guard !filteredRules.isEmpty else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            let ruleToDelete = self.filteredRules[row]
            var updatedRules = self.rewriteConfig.rules
            if let index = updatedRules.firstIndex(where: { $0.urlPattern == ruleToDelete.urlPattern && $0.httpMethod == ruleToDelete.httpMethod }) {
                updatedRules.remove(at: index)
                self.updateRewriteRules(updatedRules)
                self.tableView.reloadData()
            }
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

extension ResponseModifierSettingsController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        updateHeaderView()
        tableView.reloadData()
    }
}
