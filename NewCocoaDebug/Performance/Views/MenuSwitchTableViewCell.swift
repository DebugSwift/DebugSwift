//
//  MenuSwitchTableViewCell.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

protocol MenuSwitchTableViewCellDelegate: AnyObject {
    func menuSwitchTableViewCell(_ menuSwitchTableViewCell: MenuSwitchTableViewCell, didSetOn isOn: Bool)
}

class MenuSwitchTableViewCell: UITableViewCell {

    weak var delegate: MenuSwitchTableViewCellDelegate?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var valueSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)

        if #available(iOS 13.0, *) {
            switchControl.overrideUserInterfaceStyle = .dark
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
        contentView.backgroundColor = .black
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            valueSwitch.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc func switchValueChanged(_ sender: UISwitch) {
        delegate?.menuSwitchTableViewCell(self, didSetOn: sender.isOn)
    }
}
