//
//  ColorPickerTableViewCell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

protocol ColorPickerTableViewCellDelegate: AnyObject {
    func colorPickerCell(
        _ colorPickerCell: ColorPickerTableViewCell, didSelectColorAtIndex index: Int
    )
}

class ColorPickerTableViewCell: UITableViewCell {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    weak var delegate: ColorPickerTableViewCellDelegate?

    private var primaryColors: [UIColor] = []
    private var secondaryColors: [UIColor] = []
    private var selectedIndex = 0

    // StackView to hold the color checkboxes
    private lazy var colorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func configure(
        primaryColors: [UIColor],
        secondaryColors: [UIColor],
        selectedIndex: Int
    ) {
        self.primaryColors = primaryColors
        self.secondaryColors = secondaryColors
        self.selectedIndex = selectedIndex
        setupColorCheckBoxes()
    }

    private func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(colorStackView)
        contentView.backgroundColor = .black

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            // Positioning the stack view below the title label
            colorStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            colorStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            colorStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    private func setupColorCheckBoxes() {
        colorStackView.subviews.forEach { colorStackView.removeArrangedSubview($0) }
        for (index, color) in primaryColors.enumerated() {
            let checkBox = createCheckBox(color: color, isChecked: index == selectedIndex)
            checkBox.tag = index
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(checkBoxTapped(_:)))
            checkBox.addGestureRecognizer(tapGesture)
            colorStackView.addArrangedSubview(checkBox)
        }
    }

    private func createCheckBox(color: UIColor, isChecked: Bool) -> UIView {
        let checkBox = UIView()
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        checkBox.layer.cornerRadius = 5.0
        checkBox.layer.borderWidth = 1
        checkBox.backgroundColor = color
        checkBox.layer.borderColor = secondaryColors[0].cgColor
        checkBox.alpha = isChecked ? 1 : 0.2

        NSLayoutConstraint.activate([
            checkBox.heightAnchor.constraint(equalToConstant: 30)
        ])
        return checkBox
    }

    @objc private func checkBoxTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag else {
            return
        }
        selectedIndex = index
        updateCheckBoxes()
        delegate?.colorPickerCell(self, didSelectColorAtIndex: index)
    }

    private func updateCheckBoxes() {
        for (index, view) in colorStackView.arrangedSubviews.enumerated() {
            view.alpha = index == selectedIndex ? 1 : 0.2
        }
    }
}
