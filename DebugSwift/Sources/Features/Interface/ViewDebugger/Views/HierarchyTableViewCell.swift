//
//  HierarchyTableViewCell.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/6/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

@MainActor
protocol HierarchyTableViewCellDelegate: AnyObject {
    func hierarchyTableViewCellDidTap(cell: HierarchyTableViewCell)
    func hierarchyTableViewCellDidLongPress(cell: HierarchyTableViewCell, point: CGPoint)
}

// MARK: - Design System

private enum Design {
    enum Colors {
        static let elementName = UIColor.label
        static let frameInfo = UIColor.secondaryLabel
        static let selectedBackground = UIColor.systemGray5
        static let separatorLine = UIColor.separator
        static let hierarchyLine = UIColor.systemGray3
        static let chevronColor = UIColor.systemGray3
    }
    
    enum Typography {
        static let elementName = UIFont.systemFont(ofSize: 15, weight: .medium)
        static let elementNameBold = UIFont.systemFont(ofSize: 15, weight: .semibold)
        static let frameInfo = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    }
    
    enum Spacing {
        static let cellVerticalPadding: CGFloat = 10
        static let cellHorizontalPadding: CGFloat = 12
        static let labelSpacing: CGFloat = 4
        static let lineToContentSpacing: CGFloat = 12
        static let separatorHeight: CGFloat = 0.5
        static let chevronSize: CGFloat = 20
    }
    
    enum Layout {
        static let minimumCellHeight: CGFloat = 56
        static let hierarchyLineWidth: CGFloat = 2
        static let hierarchyLineSpacing: CGFloat = 16
    }
}

// MARK: - HierarchyTableViewCell

final class HierarchyTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let lineView: ParallelLineView = {
        let lineView = ParallelLineView()
        lineView.setContentHuggingPriority(.required, for: .horizontal)
        lineView.setContentCompressionResistancePriority(.required, for: .horizontal)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        return lineView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Design.Spacing.lineToContentSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let labelContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Design.Spacing.labelSpacing
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Design.Typography.elementName
        label.textColor = Design.Colors.elementName
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let frameLabel: UILabel = {
        let label = UILabel()
        label.font = Design.Typography.frameInfo
        label.textColor = Design.Colors.frameInfo
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = Design.Colors.chevronColor
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = Design.Colors.separatorLine
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    // MARK: - Properties
    
    var hasChildren = false {
        didSet {
            chevronImageView.isHidden = !hasChildren
        }
    }
    
    var indexPath: IndexPath?
    weak var delegate: HierarchyTableViewCellDelegate?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
        setupGestures()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = Design.Colors.selectedBackground
            return view
        }()
        
        contentView.addSubview(containerView)
        containerView.addSubview(contentStackView)
        containerView.addSubview(separatorLine)
        
        contentStackView.addArrangedSubview(lineView)
        contentStackView.addArrangedSubview(labelContainerView)
        contentStackView.addArrangedSubview(chevronImageView)
        
        labelContainerView.addSubview(labelsStackView)
        labelsStackView.addArrangedSubview(nameLabel)
        labelsStackView.addArrangedSubview(frameLabel)
        
        chevronImageView.isHidden = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Design.Spacing.cellHorizontalPadding),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Design.Spacing.cellHorizontalPadding),
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Design.Spacing.cellVerticalPadding),
            contentStackView.bottomAnchor.constraint(equalTo: separatorLine.topAnchor, constant: -Design.Spacing.cellVerticalPadding),
            
            labelsStackView.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor),
            labelsStackView.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor),
            labelsStackView.topAnchor.constraint(equalTo: labelContainerView.topAnchor),
            labelsStackView.bottomAnchor.constraint(equalTo: labelContainerView.bottomAnchor),
            
            chevronImageView.widthAnchor.constraint(equalToConstant: Design.Spacing.chevronSize),
            chevronImageView.heightAnchor.constraint(equalToConstant: Design.Spacing.chevronSize),
            
            separatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: Design.Spacing.separatorHeight)
        ])
        
        labelContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap)
        )
        contentView.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Overrides
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.containerView.backgroundColor = selected ? Design.Colors.selectedBackground.withAlphaComponent(0.3) : .clear
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        frameLabel.text = nil
        hasChildren = false
        indexPath = nil
        delegate = nil
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        delegate?.hierarchyTableViewCellDidTap(cell: self)
    }
    
    @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        let point = sender.location(ofTouch: 0, in: self)
        delegate?.hierarchyTableViewCellDidLongPress(cell: self, point: point)
    }
}
