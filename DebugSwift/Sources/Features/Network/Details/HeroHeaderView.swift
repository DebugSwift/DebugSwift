//
//  HeroHeaderView.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 18/07/26.
//

import UIKit

final class HeroHeaderView: UIView {
    private let cardContainer = UIView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    let masterSwitch = UISwitch()
    
    var onMasterToggleChanged: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        cardContainer.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        cardContainer.layer.cornerRadius = 14
        cardContainer.layer.borderWidth = 1.5
        cardContainer.layer.borderColor = UIColor.systemGreen.cgColor
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardContainer)
        
        iconContainer.backgroundColor = .systemGreen
        iconContainer.layer.cornerRadius = 8
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(iconContainer)
        
        iconImageView.image = UIImage(systemName: "bolt.fill")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        titleLabel.text = "Response Modifier"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(titleLabel)
        
        descriptionLabel.text = "Intercept and modify API responses before they reach the application."
        descriptionLabel.textColor = .lightGray
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(descriptionLabel)
        
        masterSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        masterSwitch.translatesAutoresizingMaskIntoConstraints = false
        masterSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        masterSwitch.setContentHuggingPriority(.required, for: .horizontal)
        cardContainer.addSubview(masterSwitch)
        
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            iconContainer.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: masterSwitch.leadingAnchor, constant: -12),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: masterSwitch.leadingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -16),
            
            masterSwitch.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -16),
            masterSwitch.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor)
        ])
    }
    
    @objc private func switchChanged() {
        onMasterToggleChanged?(masterSwitch.isOn)
    }
    
    func configure(isEnabled: Bool) {
        masterSwitch.isOn = isEnabled
        if isEnabled {
            cardContainer.layer.borderColor = UIColor.systemGreen.cgColor
            iconContainer.backgroundColor = .systemGreen
        } else {
            cardContainer.layer.borderColor = UIColor(white: 0.18, alpha: 1.0).cgColor
            iconContainer.backgroundColor = .systemGray
        }
    }
}
