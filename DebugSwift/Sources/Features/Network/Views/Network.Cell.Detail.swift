//
//  Network.Cell.Detail.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class NetworkTableViewCellDetail: UITableViewCell {
    let details: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(
            ofSize: 12,
            weight: .medium
        )
        textView.isScrollEnabled = false

        textView.textColor = Theme.shared.fontColor
        textView.backgroundColor = .clear
        textView.isSelectable = true
        textView.isEditable = false

        return textView
    }()

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    func setup(_ description: String, _ searched: String?, _ index: Int) {
        details.text = description

        setupHighlighted(description, searched, index)
    }

    private func setupHighlighted(_ description: String, _ searched: String?, _ index: Int) {
        guard let searched = searched, !searched.isEmpty else {
            return
        }

        let attributedString = NSMutableAttributedString(string: description)
        let highlightedWords = searched.lowercased().components(separatedBy: " ")
        let fullRange = NSRange(location: 0, length: (description as NSString).length)

        attributedString.addAttribute(.foregroundColor, value: Theme.shared.fontColor, range: fullRange)

        var wordIndex = 0

        for word in highlightedWords {
            var searchRange = fullRange
            while searchRange.location != NSNotFound {
                searchRange = (description as NSString).range(
                    of: word,
                    options: .caseInsensitive,
                    range: searchRange
                )

                if searchRange.location != NSNotFound {
                    if wordIndex == index {
                        attributedString.addAttribute(.foregroundColor, value: Theme.shared.backgroundColor, range: searchRange)
                        attributedString.addAttribute(.backgroundColor, value: UIColor.yellow, range: searchRange)
                        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: searchRange)
                    }

                    searchRange = NSRange(
                        location: searchRange.location + searchRange.length,
                        length: (description as NSString).length - (searchRange.location + searchRange.length)
                    )

                    wordIndex += 1
                }
            }
        }

        details.attributedText = attributedString
    }

    private func setupUI() {
        setupViews()
        setupConstraints()

        contentView.backgroundColor = Theme.shared.backgroundColor
        backgroundColor = Theme.shared.backgroundColor
    }

    func setupViews() {
        // Add UI components to the contentView
        contentView.addSubview(details)
    }

    func setupConstraints() {
        // Number Label
        details.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            details.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            details.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            details.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            details.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update frame or layout if needed
    }
}
