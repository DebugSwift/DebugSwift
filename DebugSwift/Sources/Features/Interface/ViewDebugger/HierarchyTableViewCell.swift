//
//  HierarchyTableViewCell.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/6/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

@MainActor
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

    private lazy var horizontalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private lazy var subtreeButton: UIButton = { [unowned self] in
        let button = UIButton(type: .custom)
        let color = UIColor(white: 0.2, alpha: 1.0)
        button.setBackgroundImage(colorImage(color: UIColor(white: .zero, alpha: 0.1)), for: .highlighted)
        
        let disclosureImage = UIImage(named: "DisclosureIndicator", in: Bundle(for: HierarchyTableViewCell.self), compatibleWith: nil)
        
        if #available(iOS 15.0, *) {
            // Use UIButtonConfiguration for iOS 15.0+
            var configuration = UIButton.Configuration.plain()
            configuration.title = NSLocalizedString("Subtree", comment: "Show the subtree starting at this element")
            configuration.image = disclosureImage
            configuration.imagePadding = 4.0
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 4.0, leading: 4.0, bottom: 4.0, trailing: 4.0)
            configuration.imagePlacement = .trailing
            
            button.configuration = configuration
            button.configurationUpdateHandler = { button in
                var config = button.configuration
                config?.baseForegroundColor = color
                config?.background.backgroundColor = button.isHighlighted ? UIColor(white: .zero, alpha: 0.1) : .clear
                button.configuration = config
            }
        } else {
            // Fallback for older iOS versions
            button.setTitle(NSLocalizedString("Subtree", comment: "Show the subtree starting at this element"), for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
            button.setImage(disclosureImage, for: .normal)
            
            let imageTextSpacing: CGFloat = 4.0
            let imageTextInset = imageTextSpacing / 2.0
            button.imageEdgeInsets = UIEdgeInsets(top: 1.0, left: imageTextInset, bottom: 0, right: -imageTextInset)
            button.titleEdgeInsets = UIEdgeInsets(top: .zero, left: -imageTextInset, bottom: .zero, right: imageTextInset)
            button.contentEdgeInsets = UIEdgeInsets(
                top: 4.0,
                left: 4.0 + imageTextInset,
                bottom: 4.0,
                right: 4.0 + imageTextInset
            )
            button.semanticContentAttribute = .forceRightToLeft
        }
        
        button.layer.cornerRadius = 4.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = color.cgColor
        button.layer.masksToBounds = true

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

        // Add horizontalScrollView to contentView
        contentView.addSubview(horizontalScrollView)

        // Add labelStackView and subtreeButton to horizontalScrollView
        horizontalScrollView.addSubview(lineView)
        horizontalScrollView.addSubview(labelStackView)
        horizontalScrollView.addSubview(subtreeButton)

        let marginsGuide = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            horizontalScrollView.leadingAnchor.constraint(equalTo: marginsGuide.leadingAnchor),
            horizontalScrollView.trailingAnchor.constraint(equalTo: marginsGuide.trailingAnchor),
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            lineView.leadingAnchor.constraint(equalTo: horizontalScrollView.leadingAnchor),
            lineView.topAnchor.constraint(equalTo: topAnchor),
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor),

            labelStackView.leadingAnchor.constraint(equalTo: lineView.trailingAnchor, constant: 5.0),
            labelStackView.centerYAnchor.constraint(equalTo: marginsGuide.centerYAnchor),

            subtreeButton.leadingAnchor.constraint(equalTo: labelStackView.trailingAnchor, constant: 5.0),
            subtreeButton.centerYAnchor.constraint(equalTo: marginsGuide.centerYAnchor),
            subtreeButton.trailingAnchor.constraint(equalTo: horizontalScrollView.trailingAnchor)
        ])
        self.subtreeLabelWidthConstraint = subtreeButton.widthAnchor.constraint(equalToConstant: .zero)

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        contentView.addGestureRecognizer(longPressGestureRecognizer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    @objc private func didTapSubtree(sender _: UIButton) {
        delegate?.hierarchyTableViewCellDidTapSubtree(cell: self)
    }

    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        let point = sender.location(ofTouch: .zero, in: self)
        delegate?.hierarchyTableViewCellDidLongPress(cell: self, point: point)
    }
}

private func colorImage(color: UIColor) -> UIImage? {
    UIGraphicsBeginImageContext(CGSize(width: 1.0, height: 1.0))
    color.setFill()
    UIRectFill(CGRect(x: .zero, y: .zero, width: 1.0, height: 1.0))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
