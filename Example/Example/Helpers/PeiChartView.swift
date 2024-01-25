//
//  PeiChartView.swift
//  Example
//
//  Created by Matheus Gois on 18/01/24.
//

import UIKit

class CircularTickView: UIView {
    var progress: CGFloat = 0.7 { didSet { setNeedsDisplay() } }

    private let startHue: CGFloat = 0.33
    private let endHue: CGFloat = 0.66
    private let outOfBoundsColor: UIColor = .lightGray

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let outerRadius = min(bounds.width, bounds.height) / 2
        let innerRadius = outerRadius * 0.7
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let tickCount = 90

        for i in 0 ..< tickCount {
            let startAngle: CGFloat = 2 * .pi * (CGFloat(i) - 0.2) / CGFloat(tickCount)
            let endAngle: CGFloat = 2 * .pi * (CGFloat(i) + 0.2) / CGFloat(tickCount)

            let path = UIBezierPath()
            path.addArc(withCenter: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.addArc(withCenter: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
            path.close()

            if #available(iOS 16.0, *) {
                if path.cgPath.intersects(UIBezierPath(rect: rect).cgPath) {
                    color(percent: CGFloat(i) / CGFloat(tickCount))
                        .setFill()
                    path.fill()
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

    private func color(percent: CGFloat) -> UIColor {
        if percent > progress {
            return outOfBoundsColor
        }

        let hue = (endHue - startHue) * percent + startHue
        return UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
    }
}
