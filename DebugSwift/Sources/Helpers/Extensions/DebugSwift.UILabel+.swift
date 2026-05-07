//
//  UILabel+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UILabel {
    func setAttributedText(title: String, subtitle: String, scale: CGFloat) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16 * scale)
        ]

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12 * scale),
            .foregroundColor: UIColor.lightGray
        ]

        let attributedString = NSMutableAttributedString()

        // Title
        let titleAttributedString = NSAttributedString(string: title, attributes: titleAttributes)
        attributedString.append(titleAttributedString)

        // Line break
        attributedString.append(NSAttributedString(string: "\n"))

        // Subtitle
        let subtitleAttributedString = NSAttributedString(
            string: subtitle, attributes: subtitleAttributes
        )
        attributedString.append(subtitleAttributedString)

        attributedText = attributedString
        numberOfLines = 0
    }
}
