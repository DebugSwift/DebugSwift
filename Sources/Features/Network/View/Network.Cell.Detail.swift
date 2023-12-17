//
//  Network.Cell.Detail.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class NetworkTableViewCellDetail: UITableViewCell {

    let details: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        textView.isScrollEnabled = false

        textView.textColor = .white
        textView.backgroundColor = .clear
        textView.isSelectable = true
        textView.isEditable = false

        return textView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    func setup(_ description: String, _ searched: String?) {
        details.text = description

        setupHighlighted(description, searched)
    }

    private func setupHighlighted(_ description: String, _ searched: String?) {
        guard let searched, !searched.isEmpty else { return }

        let attributedString = NSMutableAttributedString(string: description)
        let highlightedWords = searched.split(separator: " ")
        let fullRange = NSRange(location: 0, length: (description as NSString).length)

        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)

        for word in highlightedWords {
            let range = (description as NSString).range(of: String(word), options: .caseInsensitive)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: range)
            attributedString.addAttribute(.backgroundColor, value: UIColor.yellow, range: range)
            attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: range)
        }

        details.attributedText = attributedString
    }

    private func setupUI() {
        setupViews()
        setupConstraints()

        contentView.backgroundColor = .black
        backgroundColor = .black
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
