//
//  UITableViewCell+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UITableViewCell {
    func setup(
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        image: UIImage? = .named("chevron.right", default: "→"),
        scale: CGFloat = 1
    ) {
        // Remove subviews with tag 111
        subviews.filter { $0.tag == 111 }.forEach { $0.removeFromSuperview() }

        // Clean accessoryView
        accessoryView = nil

        // Configure textLabel
        textLabel?.text = title
        textLabel?.textColor = Theme.shared.fontColor
        textLabel?.numberOfLines = 0
        textLabel?.font = .systemFont(ofSize: 16 * scale)

        // Set attributed text if subtitle is provided
        if let subtitle, !subtitle.isEmpty {
            textLabel?.setAttributedText(title: title, subtitle: subtitle, scale: scale)
        }

        // Configure cell appearance
        backgroundColor = .clear
        selectionStyle = .none

        // Configure accessoryView
        if let image {
            let disclosureIndicator = UIImageView(image: image)
            disclosureIndicator.tintColor = Theme.shared.fontColor
            accessoryView = disclosureIndicator
        } else if let description {
            // Configure custom label for description
            let label = UILabel()
            label.text = description
            label.textColor = .darkGray
            label.numberOfLines = 0
            label.textAlignment = .right
            label.translatesAutoresizingMaskIntoConstraints = false
            label.tag = 111
            addSubview(label)

            // Set constraints for the custom label
            NSLayoutConstraint.activate([
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIScreen.main.bounds.width / 2)
            ])
        }

        // Adjust cell size
        sizeToFit()
    }
}
