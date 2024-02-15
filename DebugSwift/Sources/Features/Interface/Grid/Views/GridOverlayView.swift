//
//  GridOverlayView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class GridOverlayView: TopLevelViewWrapper {
    let GridOverlayViewMinHorizontalMiddlePartSize: NSInteger = 8
    let GridOverlayViewMinVerticalMiddlePartSize: NSInteger = 8
    let GridOverlayViewLabelFontSize: CGFloat = 9.0
    let GridOverlayViewHorizontalLabelTopOffset: CGFloat = 72.0
    let GridOverlayViewVerticalLabelRightOffset: CGFloat = 32.0
    let GridOverlayViewVerticalLabelContentOffsets: CGFloat = 4.0

    // MARK: - Properties

    lazy var horizontalLabel: UILabel = newMiddlePartLabel()
    lazy var verticalLabel: UILabel = newMiddlePartLabel()

    var gridSize: NSInteger = 28 {
        didSet {
            setNeedsDisplay()
        }
    }

    var opacity: CGFloat = 0.5 {
        didSet {
            alpha = opacity
        }
    }

    var colorScheme: GridOverlayColorScheme? = .init(
        primaryColor: .red,
        secondaryColor: Theme.shared.fontColor
    ) {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Initialization

    override func showWidgetWindow() {
        super.showWidgetWindow()
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        setupLabels()
        setupUI()
    }

    func setupUI() {
        guard
            let superview = WindowManager.window.rootViewController?.view
        else { return }
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])

        isUserInteractionEnabled = false
    }

    private func setupLabels() {
        addSubview(horizontalLabel)
        addSubview(verticalLabel)
    }

    private func newMiddlePartLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: GridOverlayViewLabelFontSize)
        label.textColor = Theme.shared.fontColor
        label.backgroundColor = .purple
        label.textAlignment = .center
        return label
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        colorScheme?.primaryColor.set()

        let lineWidth = 1.0 / UIScreen.main.scale

        var linesPerHalf = Int(frame.size.width / (2 * CGFloat(gridSize)))
        var screenSize = Int(frame.size.width)
        var middlePartSize = screenSize - linesPerHalf * 2 * gridSize
        let showsLabel = middlePartSize != 0

        if middlePartSize < GridOverlayViewMinHorizontalMiddlePartSize, showsLabel {
            linesPerHalf -=
                (GridOverlayViewMinHorizontalMiddlePartSize - middlePartSize + 2 * gridSize - 1)
                / (2 * gridSize)
            middlePartSize = screenSize - linesPerHalf * 2 * gridSize
        }

        if showsLabel {
            horizontalLabel.text = "\(middlePartSize)"
            horizontalLabel.sizeToFit()
            let labelSize = horizontalLabel.frame.size
            horizontalLabel.frame = CGRect(
                x: CGFloat(linesPerHalf) * CGFloat(gridSize) - lineWidth,
                y: GridOverlayViewHorizontalLabelTopOffset,
                width: CGFloat(middlePartSize) + 2 * lineWidth,
                height: labelSize.height
            )
        } else {
            horizontalLabel.frame = CGRect.zero
        }

        for lineIndex in 1...linesPerHalf {
            context.fill(
                CGRect(
                    x: CGFloat(lineIndex) * CGFloat(gridSize) - lineWidth,
                    y: 0.0,
                    width: lineWidth,
                    height: frame.size.height
                )
            )

            context.fill(
                CGRect(
                    x: frame.size.width - CGFloat(lineIndex) * CGFloat(gridSize),
                    y: 0.0,
                    width: lineWidth,
                    height: frame.size.height
                )
            )
        }

        linesPerHalf = Int(frame.size.height / (2 * CGFloat(gridSize)))
        screenSize = Int(frame.size.height)
        middlePartSize = screenSize - linesPerHalf * 2 * gridSize
        let showsVerticalLabel = middlePartSize != 0

        if middlePartSize < GridOverlayViewMinVerticalMiddlePartSize, showsVerticalLabel {
            linesPerHalf -=
                (GridOverlayViewMinVerticalMiddlePartSize - middlePartSize + 2 * gridSize - 1)
                / (2 * gridSize)
            middlePartSize = screenSize - linesPerHalf * 2 * gridSize
        }

        if showsVerticalLabel {
            verticalLabel.text = "\(middlePartSize)"
            verticalLabel.sizeToFit()
            let labelSize = verticalLabel.frame.size
            let labelWidth = labelSize.width + GridOverlayViewVerticalLabelContentOffsets
            verticalLabel.frame = CGRect(
                x: frame.size.width - GridOverlayViewVerticalLabelRightOffset - labelWidth,
                y: CGFloat(linesPerHalf) * CGFloat(gridSize) - lineWidth,
                width: labelWidth,
                height: CGFloat(middlePartSize) + 2 * lineWidth
            )
        } else {
            verticalLabel.frame = CGRect.zero
        }

        for lineIndex in 1...linesPerHalf {
            context.fill(
                CGRect(
                    x: 0.0,
                    y: CGFloat(lineIndex) * CGFloat(gridSize) - lineWidth,
                    width: frame.size.width,
                    height: lineWidth
                )
            )

            context.fill(
                CGRect(
                    x: 0.0,
                    y: frame.size.height - CGFloat(lineIndex) * CGFloat(gridSize),
                    width: frame.size.width,
                    height: lineWidth
                )
            )
        }
    }
}
