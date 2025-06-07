//
//  MenuSegmentedControlTableViewCell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

@MainActor
protocol MenuSegmentedControlTableViewCellDelegate: AnyObject {
    func menuSegmentedControlTableViewCell(
        _ menuSegmentedControlTableViewCell: MenuSegmentedControlTableViewCell,
        didSelectSegmentAtIndex index: Int
    )
}

final class MenuSegmentedControlTableViewCell: UITableViewCell {
    weak var delegate: MenuSegmentedControlTableViewCellDelegate?

    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        segmentedControl.isUserInteractionEnabled = true
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(
            self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged
        )
        segmentedControl.overrideUserInterfaceStyle = .dark
        return segmentedControl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func setupViews() {
        selectionStyle = .none
        contentView.addSubview(segmentedControl)
        contentView.backgroundColor = UIColor.black
        backgroundColor = UIColor.black
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16
            ),
            segmentedControl.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16
            ),
            segmentedControl.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8
            )
        ])
    }

    func configure(with titles: [String], selectedIndex: Int) {
        segmentedControl.removeAllSegments()
        for (index, title) in titles.enumerated() {
            segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = selectedIndex
    }

    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        delegate?.menuSegmentedControlTableViewCell(
            self, didSelectSegmentAtIndex: sender.selectedSegmentIndex
        )
    }
}
