//
//  ColorSwatchCell.swift
//  DebugSwift
//

import UIKit

final class ColorSwatchCell: UITableViewCell {

    static let identifier = "ColorSwatchCell"

    private let swatchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        view.clipsToBounds = true
        return view
    }()

    private let hexLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .lightGray
        return label
    }()

    private let usageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()

    private let detailsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        accessoryType = .disclosureIndicator
        selectionStyle = .default

        contentView.addSubview(swatchView)
        contentView.addSubview(detailsStack)
        contentView.addSubview(usageLabel)

        detailsStack.addArrangedSubview(hexLabel)
        detailsStack.addArrangedSubview(nameLabel)

        usageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            swatchView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            swatchView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            swatchView.widthAnchor.constraint(equalToConstant: 44),
            swatchView.heightAnchor.constraint(equalToConstant: 44),

            detailsStack.leadingAnchor.constraint(equalTo: swatchView.trailingAnchor, constant: 12),
            detailsStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailsStack.trailingAnchor.constraint(lessThanOrEqualTo: usageLabel.leadingAnchor, constant: -8),

            usageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            usageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            usageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    func configure(with color: ColorInfo) {
        swatchView.backgroundColor = color.color
        hexLabel.text = color.hex
        nameLabel.text = color.rgbString
        usageLabel.text = "\(color.usageCount)×"
    }
}
