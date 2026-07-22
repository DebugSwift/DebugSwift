//
//  PaletteHeaderView.swift
//  DebugSwift
//

import UIKit

final class PaletteHeaderView: UITableViewHeaderFooterView {

    static let identifier = "PaletteHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .black
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            countLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, count: Int) {
        titleLabel.text = title.uppercased()
        countLabel.text = "\(count) color\(count == 1 ? "" : "s")"
    }
}
