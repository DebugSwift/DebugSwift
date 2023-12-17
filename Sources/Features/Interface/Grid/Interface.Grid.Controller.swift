//
//  Interface.Grid.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

enum GridOverlaySettingsSection: Int {
    case toggle
    case settings
}

enum GridOverlaySettingsRow: Int {
    case size
    case opacity
    case color
}

class InterfaceGridController: BaseTableController, MenuSwitchTableViewCellDelegate,
    SliderTableViewCellDelegate, ColorPickerTableViewCellDelegate {
    private let switchCellIdentifier = "MenuSwitchTableViewCell"
    private let sliderCellIdentifier = "SliderTableViewCell"
    private let colorPickerCellIdentifier = "ColorPickerTableViewCell"

    private let minGridSize: CGFloat = 4.0
    private let maxGridSize: CGFloat = 64.0
    private let minOpacity: CGFloat = 0.1
    private let maxOpacity: CGFloat = 1.0
    private let semiTransparencyRatio: CGFloat = 0.2

    private var primaryGridColors: [UIColor] = []
    private var secondaryGridColors: [UIColor] = []

    var userInterfaceToolkit: UserInterfaceToolkit = .shared

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Grid overlay"

        tableView.register(MenuSwitchTableViewCell.self, forCellReuseIdentifier: switchCellIdentifier)
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: sliderCellIdentifier)
        tableView.register(
            ColorPickerTableViewCell.self, forCellReuseIdentifier: colorPickerCellIdentifier
        )

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .black
        tableView.separatorStyle = .singleLine

        setupGridColors()
    }

    override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }

    // MARK: - Private methods

    private func setupGridColors() {
        var primaryColors: [UIColor] = []
        var secondaryColors: [UIColor] = []
        for colorScheme in userInterfaceToolkit.gridOverlayColorSchemes {
            primaryColors.append(colorScheme.primaryColor)
            secondaryColors.append(colorScheme.secondaryColor)
        }
        primaryGridColors = primaryColors
        secondaryGridColors = secondaryColors
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        2
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = GridOverlaySettingsSection(rawValue: section) else {
            return 0
        }
        switch tableViewSection {
        case .toggle:
            return 1
        case .settings:
            return userInterfaceToolkit.isGridOverlayShown ? 3 : 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        guard let tableViewSection = GridOverlaySettingsSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        switch tableViewSection {
        case .toggle:
            let switchCell =
                tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier, for: indexPath)
                    as! MenuSwitchTableViewCell
            switchCell.titleLabel.text = "Show grid overlay"
            switchCell.valueSwitch.isOn = userInterfaceToolkit.isGridOverlayShown
            switchCell.delegate = self
            return switchCell
        case .settings:
            return cellInSettingsSection(for: indexPath)
        }
    }

    private func cellInSettingsSection(for indexPath: IndexPath) -> UITableViewCell {
        guard let settingsRow = GridOverlaySettingsRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        switch settingsRow {
        case .size:
            let sliderCell =
                tableView.dequeueReusableCell(withIdentifier: sliderCellIdentifier, for: indexPath)
                    as! SliderTableViewCell
            sliderCell.titleLabel.text = "Size"
            sliderCell.delegate = self
            sliderCell.setMinValue(minGridSize)
            sliderCell.setMaxValue(maxGridSize)
            sliderCell.setValue(CGFloat(userInterfaceToolkit.gridOverlay.gridSize))
            return sliderCell
        case .opacity:
            let sliderCell =
                tableView.dequeueReusableCell(withIdentifier: sliderCellIdentifier, for: indexPath)
                    as! SliderTableViewCell
            sliderCell.titleLabel.text = "Opacity"
            sliderCell.delegate = self
            sliderCell.setMinValue(minOpacity)
            sliderCell.setMaxValue(maxOpacity)
            sliderCell.setValue(userInterfaceToolkit.gridOverlay.opacity)
            return sliderCell
        case .color:
            let colorPickerCell =
                tableView.dequeueReusableCell(
                    withIdentifier: colorPickerCellIdentifier,
                    for: indexPath
                ) as! ColorPickerTableViewCell

            colorPickerCell.titleLabel.text = "Color"
            colorPickerCell.delegate = self
            colorPickerCell.configure(
                primaryColors: primaryGridColors,
                secondaryColors: secondaryGridColors,
                selectedIndex: userInterfaceToolkit.selectedGridOverlayColorSchemeIndex
            )
            return colorPickerCell
        }
    }

    override func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let settingsRow = GridOverlaySettingsRow(rawValue: indexPath.row) else {
            return .zero
        }
        switch settingsRow {
        case .size, .opacity:
            return 80
        case .color:
            return 300
        }
    }

    override func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let tableViewSection = GridOverlaySettingsSection(rawValue: section) else {
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

            return userInterfaceToolkit.isGridOverlayShown ? label : nil
        }
    }

    // MARK: - MenuSwitchTableViewCellDelegate

    func menuSwitchTableViewCell(_: MenuSwitchTableViewCell, didSetOn isOn: Bool) {
        userInterfaceToolkit.isGridOverlayShown = isOn
        let sectionsToReload = IndexSet(integer: GridOverlaySettingsSection.settings.rawValue)
        tableView.reloadSections(sectionsToReload, with: .fade)
    }

    // MARK: - SliderTableViewCellDelegate

    func sliderCell(_ sliderCell: SliderTableViewCell, didSelectValue value: CGFloat) {
        guard let indexPath = tableView.indexPath(for: sliderCell),
              let settingsRow = GridOverlaySettingsRow(rawValue: indexPath.row)
        else {
            return
        }
        switch settingsRow {
        case .size:
            userInterfaceToolkit.gridOverlay.gridSize = NSInteger(value)
        case .opacity:
            userInterfaceToolkit.gridOverlay.opacity = value
        case .color:
            break
        }
    }

    func sliderCellDidStartEditingValue(_ sliderCell: SliderTableViewCell) {
        guard let indexPath = tableView.indexPath(for: sliderCell),
              let settingsRow = GridOverlaySettingsRow(rawValue: indexPath.row)
        else {
            return
        }
        if settingsRow == .size {
            setShouldMakeGridSemiTransparent(true)
        }
    }

    func sliderCellDidEndEditingValue(_ sliderCell: SliderTableViewCell) {
        guard let indexPath = tableView.indexPath(for: sliderCell),
              let settingsRow = GridOverlaySettingsRow(rawValue: indexPath.row)
        else {
            return
        }
        if settingsRow == .size {
            setShouldMakeGridSemiTransparent(false)
        }
    }

    private func setShouldMakeGridSemiTransparent(_ shouldMakeGridSemiTransparent: Bool) {
        let opacity = userInterfaceToolkit.gridOverlay.opacity
        var targetAlpha = opacity
        if shouldMakeGridSemiTransparent {
            targetAlpha *= semiTransparencyRatio
        }
        targetAlpha = max(min(0.2, opacity), targetAlpha)
        UIView.animate(
            withDuration: 0.35, delay: 0.0, options: .beginFromCurrentState,
            animations: {
                self.userInterfaceToolkit.gridOverlay.alpha = targetAlpha
            }, completion: nil
        )
    }

    // MARK: - ColorPickerTableViewCellDelegate

    func colorPickerCell(
        _: ColorPickerTableViewCell, didSelectColorAtIndex index: Int
    ) {
        userInterfaceToolkit.setSelectedGridOverlayColorSchemeIndex(index)
    }
}
