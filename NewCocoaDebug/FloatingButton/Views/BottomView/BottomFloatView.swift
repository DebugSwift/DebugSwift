//
//  BottomFloatView.swift
//  NewCocoaDebug
//
//  Created by 周晓瑞 on 2018/6/13.
//  Copyright © 2018年 apple. All rights reserved.
//

import UIKit

enum BottomFloatViewType {
    /// Black, default
    case black
    /// Cancel is red
    case red
}

class BottomFloatView: UIView {
    var type: BottomFloatViewType = BottomFloatViewType.black {
        didSet {
            if type == BottomFloatViewType.red {
                backgroundColor = UIColor.red
                setNeedsDisplay()
            }
        }
    }
    var insideBottomSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    fileprivate lazy var tipsLab = UILabel()
    fileprivate lazy var maskLayer = CAShapeLayer()

   override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUp() {
        backgroundColor = UIColor(white: 0.0, alpha: 0.65)
        layer.mask = maskLayer

        tipsLab.font = UIFont.systemFont(ofSize: 15)
        tipsLab.textColor = UIColor.white
        tipsLab.textAlignment = NSTextAlignment.right
        addSubview(tipsLab)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        tipsLab.frame = bounds
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let scale: CGFloat = insideBottomSelected ? 1.0 : 0.8
        let bezierPath = UIBezierPath(arcCenter: CGPoint(x: bounds.width, y: bounds.height), radius: bounds.width * scale, startAngle: CGFloat(Double.pi), endAngle: CGFloat(1.5 * Double.pi), clockwise: true)
        bezierPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        bezierPath.close()
        maskLayer.path = bezierPath.cgPath

        if type == BottomFloatViewType.red {
           let circleB1 = UIBezierPath(arcCenter: CGPoint(x: bounds.width * 0.7, y: bounds.height * 0.7), radius: 10, startAngle: 0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
           circleB1.lineWidth = 3.0
            UIColor.white.setStroke()
           circleB1.stroke()
        }
    }
}
