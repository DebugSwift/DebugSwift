//
//  Network.Cell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class NetworkTableViewCell: UITableViewCell {
    let methodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(
            ofSize: 17,
            weight: .bold
        )
        label.textColor = .gray
        return label
    }()

    let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(
            ofSize: 18,
            weight: .medium
        )
        label.textColor = UIColor.white
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.layer.cornerRadius = 1
        label.layer.borderWidth = 0
        return label
    }()

    let statusCodeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(
            ofSize: 17,
            weight: .bold
        )
        label.textColor = .green
        label.textAlignment = .center
        return label
    }()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(
            ofSize: 13
        )
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()

    let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(
            ofSize: 12,
            weight: .semibold
        )
        label.textColor = UIColor.white
        label.textColor = .green
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    func setup(_ model: HttpModel) {
        methodLabel.text = "[\(model.method ?? "")]"
        numberLabel.text = model.id
        statusCodeLabel.text = model.statusCode
        descriptionLabel.text = model.url?.absoluteString
        timestampLabel.text = model.startTime

        let textColor: UIColor
        if model.isSuccess {
            textColor = .green
        } else {
            textColor = .red
        }
        numberLabel.textColor = textColor
        statusCodeLabel.textColor = textColor
        timestampLabel.textColor = textColor
    }

    private func setupUI() {
        setupViews()
        setupConstraints()
    }

    func setupViews() {
        contentView.addSubview(methodLabel)
        contentView.addSubview(numberLabel)
        contentView.addSubview(statusCodeLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(timestampLabel)

        contentView.backgroundColor = UIColor.black
        backgroundColor = UIColor.black
        selectionStyle = .none
    }

    func setupConstraints() {
        // Number Label
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        let numberWidthConstraint = numberLabel.widthAnchor.constraint(equalToConstant: 40)
        numberWidthConstraint.priority = UILayoutPriority(999) // Lower priority to avoid conflicts
        NSLayoutConstraint.activate([
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 8),
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            numberWidthConstraint
        ])

        // Method Label
        methodLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            methodLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            methodLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        ])

        // Timestamp Label
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: methodLabel.trailingAnchor, constant: 8),

            timestampLabel.centerYAnchor.constraint(equalTo: methodLabel.centerYAnchor)
        ])

        // Description Label
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        let descriptionLeadingConstraint = descriptionLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 4)
        descriptionLeadingConstraint.priority = UILayoutPriority(998) // Lower priority to avoid conflicts
        
        // Fallback leading constraint
        let descriptionFallbackLeadingConstraint = descriptionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
        descriptionFallbackLeadingConstraint.priority = UILayoutPriority(997)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: methodLabel.bottomAnchor, constant: 4),
            descriptionLeadingConstraint,
            descriptionFallbackLeadingConstraint,
            descriptionLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -60
            ),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])

        // Status Code Label
        statusCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusCodeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusCodeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
}
