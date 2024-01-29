//
//  ParallelLineView.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/7/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit
import CoreGraphics

/// A view that draws one or more parallel vertical lines.
final class ParallelLineView: UIView {
    var lineColors = [Theme.shared.setupBackgroundColor()]

    var lineWidth: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
            invalidateIntrinsicContentSize()
        }
    }

    var lineSpacing: CGFloat = 12.0 {
        didSet {
            setNeedsDisplay()
            invalidateIntrinsicContentSize()
        }
    }

    var lineCount: Int = .zero {
        didSet {
            setNeedsDisplay()
            invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.shared.setupBackgroundColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard lineCount > .zero && !lineColors.isEmpty else {
            return
        }
        var x: CGFloat = lineSpacing
        (0..<lineCount).forEach { index in
            lineColors[index % lineColors.count].setFill()
            let rect = CGRect(x: x, y: .zero, width: lineWidth, height: bounds.height)
            UIRectFill(rect)
            x += lineWidth + lineSpacing
        }
    }

    override var intrinsicContentSize: CGSize {
        guard lineCount > .zero else {
            return CGSize(width: .zero, height: UIView.noIntrinsicMetric)
        }
        return CGSize(width: CGFloat(lineCount) * (lineWidth + lineSpacing), height: UIView.noIntrinsicMetric)
    }
}
