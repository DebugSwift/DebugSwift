//
//  SettingCell.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 18/07/26.
//

import UIKit

final class SettingCell: UITableViewCell {
    private let iconContainerView = UIView()
    private let iconImageView = UIImageView()
    let titleLabel = UILabel()
    let detailLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .black
        selectionStyle = .none
        
        iconContainerView.layer.cornerRadius = 6
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconContainerView)
        
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.addSubview(iconImageView)
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        detailLabel.textColor = .lightGray
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailLabel)
        
        NSLayoutConstraint.activate([
            iconContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 28),
            iconContainerView.heightAnchor.constraint(equalToConstant: 28),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(title: String, iconName: String, iconBgColor: UIColor, detailText: String? = nil, accessoryView: UIView? = nil) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: iconName)
        iconContainerView.backgroundColor = iconBgColor
        detailLabel.text = detailText
        self.accessoryView = accessoryView
        
        if accessoryView == nil {
            accessoryType = .disclosureIndicator
            selectionStyle = .default
            detailLabel.isHidden = true
        } else {
            accessoryType = .none
            selectionStyle = .none
            detailLabel.isHidden = (detailText == nil)
        }
    }
}
