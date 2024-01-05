//
//  HierarchyTableViewCell.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/6/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

protocol HierarchyTableViewCellDelegate: AnyObject {
    func hierarchyTableViewCellDidTapSubtree(cell: HierarchyTableViewCell)
    func hierarchyTableViewCellDidLongPress(cell: HierarchyTableViewCell, point: CGPoint)
}

final class HierarchyTableViewCell: UITableViewCell {
    private lazy var labelStackView: UIStackView = { [unowned self] in
        let stackView = UIStackView()
        stackView.spacing = 3.0
        stackView.axis = .vertical
        stackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(frameLabel)
        return stackView
    }()
    
    let lineView: ParallelLineView = {
        let lineView = ParallelLineView()
        lineView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        return lineView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let frameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var subtreeButton: UIButton = { [unowned self] in
        let button = UIButton(type: .custom)
        let color = UIColor(white: 0.2, alpha: 1.0)
        button.setBackgroundImage(colorImage(color: UIColor(white: 0.0, alpha: 0.1)), for: .highlighted)
        button.setTitle(NSLocalizedString("Subtree", comment: "Show the subtree starting at this element"), for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        let disclosureImage = UIImage(named: "DisclosureIndicator", in: Bundle(for: HierarchyTableViewCell.self), compatibleWith: nil)
        button.setImage(disclosureImage, for: .normal)
        button.layer.cornerRadius = 4.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = color.cgColor
        button.layer.masksToBounds = true
        
        let imageTextSpacing: CGFloat = 4.0
        let imageTextInset = imageTextSpacing / 2.0
        button.imageEdgeInsets = UIEdgeInsets(top: 1.0, left: imageTextInset, bottom: 0, right: -imageTextInset)
        button.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: -imageTextInset, bottom: 0.0, right: imageTextInset)
        button.contentEdgeInsets = UIEdgeInsets(top: 4.0, left:
            4.0 + imageTextInset, bottom: 4.0, right: 4.0 + imageTextInset)
        button.semanticContentAttribute = .forceRightToLeft
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        button.addTarget(self, action: #selector(didTapSubtree(sender:)), for: .touchUpInside)
        
        return button
    }()
    
    // Used to hide/unhide the subtree button.
    private var subtreeLabelWidthConstraint: NSLayoutConstraint?
    
    var showSubtreeButton = false {
        didSet {
            subtreeLabelWidthConstraint?.isActive = !showSubtreeButton
        }
    }
    
    var indexPath: IndexPath?
    
    weak var delegate: HierarchyTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectedBackgroundView = {
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
            return backgroundView
        }()
        
        contentView.addSubview(lineView)
        contentView.addSubview(labelStackView)
        contentView.addSubview(subtreeButton)

        let marginsGuide = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: marginsGuide.leadingAnchor),
            lineView.topAnchor.constraint(equalTo: topAnchor),
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            labelStackView.leadingAnchor.constraint(equalTo: lineView.trailingAnchor, constant: 5.0),
            labelStackView.centerYAnchor.constraint(equalTo: marginsGuide.centerYAnchor),
            subtreeButton.leadingAnchor.constraint(equalTo: labelStackView.trailingAnchor, constant: 5.0),
            subtreeButton.centerYAnchor.constraint(equalTo: marginsGuide.centerYAnchor),
            subtreeButton.trailingAnchor.constraint(equalTo: marginsGuide.trailingAnchor),
        ])
        subtreeLabelWidthConstraint = subtreeButton.widthAnchor.constraint(equalToConstant: 0.0)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        contentView.addGestureRecognizer(longPressGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Actions
    
    @objc private func didTapSubtree(sender: UIButton) {
        delegate?.hierarchyTableViewCellDidTapSubtree(cell: self)
    }
    
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        let point = sender.location(ofTouch: 0, in: self)
        delegate?.hierarchyTableViewCellDidLongPress(cell: self, point: point)
    }
}

private func colorImage(color: UIColor) -> UIImage? {
    UIGraphicsBeginImageContext(CGSize(width: 1.0, height: 1.0))
    color.setFill()
    UIRectFill(CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
