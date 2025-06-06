//
//  StepperTableViewCell.swift
//  DebugSwift
//
//  Created by DebugSwift on 04/06/25.
//

import UIKit

final class StepperTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var value: Int = 0
    private var suffix: String = ""
    private var onValueChanged: ((Int) -> Void)?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .black
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(
        title: String,
        value: Int,
        suffix: String,
        min: Int,
        max: Int,
        step: Int,
        onValueChanged: @escaping (Int) -> Void
    ) {
        self.titleLabel.text = title
        self.value = value
        self.suffix = suffix
        self.onValueChanged = onValueChanged
        updateValueLabel()
    }
    
    // MARK: - Private Methods
    
    private func updateValueLabel() {
        valueLabel.text = "\(value) \(suffix)"
    }
} 