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
        image: UIImage? = UIImage(named: "chevron.right")
    ) {
        textLabel?.text = title
        textLabel?.textColor = .white
        textLabel?.numberOfLines = .zero

        if let subtitle {
            textLabel?.setAttributedText(title: title, subtitle: subtitle)
        }

        backgroundColor = .clear
        selectionStyle = .none

        if let image {
            let disclosureIndicator = UIImageView(image: image)
            disclosureIndicator.tintColor = .white
            accessoryView = disclosureIndicator
            accessoryType = .disclosureIndicator
        } else if let description {
            let label = UILabel()
            label.text = title
            label.textColor = .darkGray
            label.numberOfLines = .zero
            label.textAlignment = .right

            label.text = description
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)

            NSLayoutConstraint.activate([
                label.centerYAnchor.constraint(
                    equalTo: centerYAnchor
                ),
                label.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -16
                ),
                label.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: UIScreen.main.bounds.width/2
                )
            ])
        }
    }
}
