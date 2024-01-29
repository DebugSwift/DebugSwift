//
//  MenuSwitchTableViewCell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

protocol MenuSwitchTableViewCellDelegate: AnyObject {
    func menuSwitchTableViewCell(_ cell: MenuSwitchTableViewCell, didSetOn isOn: Bool)
}

final class MenuSwitchTableViewCell: UITableViewCell {
    weak var delegate: MenuSwitchTableViewCellDelegate?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.shared.setupFontColor()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var valueSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)

        if #available(iOS 13.0, *) {
            switchControl.overrideUserInterfaceStyle = Theme.shared.setupInterfaceStyle()
        }
        switchControl.thumbTintColor = .white

        return switchControl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueSwitch)
        contentView.backgroundColor = Theme.shared.setupBackgroundColor()
        backgroundColor = Theme.shared.setupBackgroundColor()
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueSwitch.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16
            ),
            valueSwitch.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc func switchValueChanged(_ sender: UISwitch) {
        delegate?.menuSwitchTableViewCell(self, didSetOn: sender.isOn)
    }
}

extension MenuSwitchTableViewCell {
    static let identifier = "MenuSwitchTableViewCell"
}
