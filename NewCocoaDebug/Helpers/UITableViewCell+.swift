//
//  UITableViewCell+.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UITableViewCell {
    func setup(
        title: String,
        subtitle: String? = nil,
        image: UIImage? = UIImage(named: "chevron.right")
    ) {
        textLabel?.text = title
        textLabel?.textColor = .white
        textLabel?.numberOfLines = .zero

        detailTextLabel?.text = subtitle
        detailTextLabel?.textColor = .white
        detailTextLabel?.numberOfLines = .zero

        backgroundColor = .clear
        selectionStyle = .none

        let disclosureIndicator = UIImageView(image: image)
        disclosureIndicator.tintColor = .white
        accessoryView = disclosureIndicator
        accessoryType = .disclosureIndicator
    }
}
