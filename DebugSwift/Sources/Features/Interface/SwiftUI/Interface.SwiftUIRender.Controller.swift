//
//  Interface.SwiftUIRender.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025/01/27.
//

import UIKit

enum SwiftUIRenderSettingsSection: Int {
    case toggle
    case settings
    case actions
}

enum SwiftUIRenderSettingsRow: Int {
    case persistentOverlays
    case overlayDuration
    case loggingEnabled
    case overlayStyle
}

enum SwiftUIRenderActionsRow: Int {
    case clearStats
    case clearPersistentOverlays
}

final class InterfaceSwiftUIRenderController: BaseTableController, 
    MenuSwitchTableViewCellDelegate, SliderTableViewCellDelegate {
    
    private let switchCellIdentifier = "MenuSwitchTableViewCell"
    private let sliderCellIdentifier = "SliderTableViewCell"
    private let buttonCellIdentifier = "ButtonTableViewCell"
    private let selectionCellIdentifier = "SelectionTableViewCell"
    
    private let minDuration: CGFloat = 0.1
    private let maxDuration: CGFloat = 3.0
    
    var renderTracker: SwiftUIRenderTracker = .shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SwiftUI Render Tracking"
        
        tableView.register(MenuSwitchTableViewCell.self, forCellReuseIdentifier: switchCellIdentifier)
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: sliderCellIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: buttonCellIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: selectionCellIdentifier)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.black
        tableView.separatorStyle = .singleLine
        
        // Ensure proper content size calculation
        tableView.contentInsetAdjustmentBehavior = .automatic
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in _: UITableView) -> Int {
        3
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = SwiftUIRenderSettingsSection(rawValue: section) else {
            return 0
        }
        switch tableViewSection {
        case .toggle:
            return 1
        case .settings:
            return renderTracker.isEnabled ? 4 : 0
        case .actions:
            return renderTracker.isEnabled ? 2 : 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableViewSection = SwiftUIRenderSettingsSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch tableViewSection {
        case .toggle:
            let switchCell = tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier, for: indexPath) as! MenuSwitchTableViewCell
            switchCell.titleLabel.text = "Enable SwiftUI render tracking"
            switchCell.valueSwitch.isOn = renderTracker.isEnabled
            switchCell.delegate = self
            return switchCell
            
        case .settings:
            return cellInSettingsSection(for: indexPath)
            
        case .actions:
            return cellInActionsSection(for: indexPath)
        }
    }
    
    private func cellInSettingsSection(for indexPath: IndexPath) -> UITableViewCell {
        guard let settingsRow = SwiftUIRenderSettingsRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        
        switch settingsRow {
        case .persistentOverlays:
            let switchCell = tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier, for: indexPath) as! MenuSwitchTableViewCell
            switchCell.titleLabel.text = "Persistent overlays"
            switchCell.valueSwitch.isOn = renderTracker.persistentOverlays
            switchCell.delegate = self
            switchCell.tag = 100 + indexPath.row // Offset to distinguish from main toggle
            return switchCell
            
        case .overlayDuration:
            let sliderCell = tableView.dequeueReusableCell(withIdentifier: sliderCellIdentifier, for: indexPath) as! SliderTableViewCell
            sliderCell.titleLabel.text = "Overlay duration"
            sliderCell.delegate = self
            sliderCell.setMinValue(minDuration)
            sliderCell.setMaxValue(maxDuration)
            sliderCell.setValue(CGFloat(renderTracker.overlayDuration))
            return sliderCell
            
        case .loggingEnabled:
            let switchCell = tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier, for: indexPath) as! MenuSwitchTableViewCell
            switchCell.titleLabel.text = "Console logging"
            switchCell.valueSwitch.isOn = renderTracker.loggingEnabled
            switchCell.delegate = self
            switchCell.tag = 100 + indexPath.row // Offset to distinguish from main toggle
            return switchCell
            
        case .overlayStyle:
            let cell = tableView.dequeueReusableCell(withIdentifier: selectionCellIdentifier, for: indexPath)
            cell.textLabel?.text = "Overlay style"
            cell.detailTextLabel?.text = overlayStyleDisplayName(renderTracker.overlayStyle)
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .lightGray
            cell.backgroundColor = .black
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    private func cellInActionsSection(for indexPath: IndexPath) -> UITableViewCell {
        guard let actionsRow = SwiftUIRenderActionsRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: buttonCellIdentifier, for: indexPath)
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .systemBlue
        cell.textLabel?.textAlignment = .center
        
        switch actionsRow {
        case .clearStats:
            cell.textLabel?.text = "Clear render statistics"
        case .clearPersistentOverlays:
            cell.textLabel?.text = "Clear persistent overlays"
        }
        
        return cell
    }
    
    override func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let tableViewSection = SwiftUIRenderSettingsSection(rawValue: indexPath.section) else {
            return 60
        }
        
        switch tableViewSection {
        case .toggle:
            return 60
        case .settings:
            if let settingsRow = SwiftUIRenderSettingsRow(rawValue: indexPath.row), 
               settingsRow == .overlayDuration {
                return 80 // Extra height for slider
            }
            return 60
        case .actions:
            return 60
        }
    }
    
    override func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let tableViewSection = SwiftUIRenderSettingsSection(rawValue: section) else {
            return nil
        }
        
        switch tableViewSection {
        case .toggle:
            return nil
        case .settings:
            let label = UILabel()
            label.text = "   Settings\n"
            label.textColor = .darkGray
            label.numberOfLines = .zero
            return renderTracker.isEnabled ? label : nil
        case .actions:
            let label = UILabel()
            label.text = "   Actions\n"
            label.textColor = .darkGray
            label.numberOfLines = .zero
            return renderTracker.isEnabled ? label : nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let tableViewSection = SwiftUIRenderSettingsSection(rawValue: indexPath.section) else {
            return
        }
        
        switch tableViewSection {
        case .toggle:
            break
        case .settings:
            if let settingsRow = SwiftUIRenderSettingsRow(rawValue: indexPath.row) {
                if settingsRow == .overlayStyle {
                    showOverlayStylePicker()
                }
            }
        case .actions:
            if let actionsRow = SwiftUIRenderActionsRow(rawValue: indexPath.row) {
                switch actionsRow {
                case .clearStats:
                    renderTracker.clearStats()
                    showAlert(title: "Stats Cleared", message: "All render statistics have been cleared.")
                case .clearPersistentOverlays:
                    renderTracker.clearAllPersistentOverlays()
                    showAlert(title: "Overlays Cleared", message: "All persistent overlays have been removed.")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func overlayStyleDisplayName(_ style: SwiftUIRenderTracker.RenderOverlayStyle) -> String {
        switch style {
        case .border:
            return "Border"
        case .borderWithCount:
            return "Border with count"
        case .none:
            return "None (logging only)"
        }
    }
    
    private func showOverlayStylePicker() {
        let alert = UIAlertController(title: "Select Overlay Style", message: nil, preferredStyle: .actionSheet)
        
        let styles: [SwiftUIRenderTracker.RenderOverlayStyle] = [.border, .borderWithCount, .none]
        
        for style in styles {
            let action = UIAlertAction(title: overlayStyleDisplayName(style), style: .default) { [weak self] _ in
                self?.renderTracker.overlayStyle = style
                self?.tableView.reloadData()
            }
            if style == renderTracker.overlayStyle {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - MenuSwitchTableViewCellDelegate
    
    func menuSwitchTableViewCell(_ cell: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        if cell.tag >= 100 {
            // Settings switches
            let settingsRow = cell.tag - 100
            switch SwiftUIRenderSettingsRow(rawValue: settingsRow) {
            case .persistentOverlays:
                renderTracker.persistentOverlays = isOn
                // Reload table to ensure proper layout after persistence change
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                    self?.tableView.layoutIfNeeded()
                }
            case .loggingEnabled:
                renderTracker.loggingEnabled = isOn
            default:
                break
            }
        } else {
            // Main toggle
            renderTracker.isEnabled = isOn
            UserInterfaceToolkit.shared.swiftUIRenderTrackingEnabled = isOn
            let sectionsToReload = IndexSet([
                SwiftUIRenderSettingsSection.settings.rawValue,
                SwiftUIRenderSettingsSection.actions.rawValue
            ])
            tableView.reloadSections(sectionsToReload, with: .fade)
        }
    }
    
    // MARK: - SliderTableViewCellDelegate
    
    func sliderCell(_ sliderCell: SliderTableViewCell, didSelectValue value: CGFloat) {
        guard let indexPath = tableView.indexPath(for: sliderCell),
              let settingsRow = SwiftUIRenderSettingsRow(rawValue: indexPath.row) else {
            return
        }
        
        switch settingsRow {
        case .overlayDuration:
            renderTracker.overlayDuration = TimeInterval(value)
        default:
            break
        }
    }
    
    func sliderCellDidStartEditingValue(_ sliderCell: SliderTableViewCell) {
        // Optional: Add behavior when user starts editing
    }
    
    func sliderCellDidEndEditingValue(_ sliderCell: SliderTableViewCell) {
        // Optional: Add behavior when user ends editing
    }
} 