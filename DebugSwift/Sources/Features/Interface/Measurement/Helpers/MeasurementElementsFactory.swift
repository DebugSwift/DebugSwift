//
//  MeasurementElementsFactory.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

class MeasurementElementsFactory {
    let styleManager: StyleManager

    init(styleManager: StyleManager) {
        self.styleManager = styleManager
    }

    func createMeasurementLabel(withText text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = styleManager.primaryColor.cgColor
        containerView.layer.masksToBounds = true

        let label = UILabel()
        label.text = text
        label.textColor = styleManager.primaryColor
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 1
        label.sizeToFit()
        label.isUserInteractionEnabled = false

        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 2

        let labelWidth = label.frame.width + horizontalPadding * 2
        let labelHeight = label.frame.height + verticalPadding * 2

        containerView.frame = CGRect(x: 0, y: 0, width: labelWidth, height: labelHeight)

        label.frame = CGRect(
            x: horizontalPadding,
            y: verticalPadding,
            width: label.frame.width,
            height: label.frame.height
        )
        containerView.addSubview(label)

        containerView.center = CGPoint(
            x: containerView.superview?.bounds.midX ?? 0,
            y: containerView.superview?.bounds.midY ?? 0
        )

        return containerView
    }

    // Calculate

    func setPath(in mainView: UIView, for view: UIView, with attachedWindow: UIWindow) -> CAShapeLayer {
        let globalSelectedRect = view.superview?.convert(view.frame, to: attachedWindow)

        let path = UIBezierPath(rect: globalSelectedRect ?? CGRect.zero)
        let shape = CAShapeLayer()
        shape.bounds = mainView.bounds
        shape.position = mainView.center
        shape.lineWidth = 3
        shape.borderColor = styleManager.primaryColor.cgColor
        shape.strokeColor = styleManager.primaryColor.cgColor
        shape.path = path.cgPath
        shape.fillColor = UIColor.clear.cgColor
        mainView.layer.addSublayer(shape)

        return shape
    }

    func setPath(in mainView: UIView, forCompare view: UIView, with attachedWindow: UIWindow) -> CAShapeLayer {
        let globalSelectedRect = view.superview?.convert(view.frame, to: attachedWindow)

        let path = UIBezierPath(rect: globalSelectedRect ?? .zero)
        let shape = CAShapeLayer()
        shape.bounds = mainView.bounds
        shape.position = mainView.center
        shape.lineWidth = 1
        shape.borderColor = styleManager.secondaryColor.cgColor
        shape.strokeColor = styleManager.secondaryColor.cgColor
        shape.lineDashPattern = [2, 2]
        shape.path = path.cgPath
        shape.fillColor = UIColor.clear.cgColor
        mainView.layer.addSublayer(shape)

        return shape
    }

    func setLines(in mainView: UIView, for view: UIView, with attachedWindow: UIWindow) -> [CAShapeLayer] {
        guard let globalSelectedRect = view.superview?.convert(view.frame, to: attachedWindow) else { return [] }

        let left = UIBezierPath()
        left.move(to: CGPoint(x: globalSelectedRect.origin.x, y: 0))
        left.addLine(to: CGPoint(x: globalSelectedRect.origin.x, y: mainView.frame.size.height))

        let right = UIBezierPath()
        right.move(to: CGPoint(x: globalSelectedRect.maxX, y: 0))
        right.addLine(to: CGPoint(x: globalSelectedRect.maxX, y: mainView.frame.size.height))

        let top = UIBezierPath()
        top.move(to: CGPoint(x: 0, y: globalSelectedRect.origin.y))
        top.addLine(to: CGPoint(x: mainView.frame.size.height, y: globalSelectedRect.origin.y))

        let bottom = UIBezierPath()
        bottom.move(to: CGPoint(x: 0, y: globalSelectedRect.maxY))
        bottom.addLine(to: CGPoint(x: mainView.frame.size.height, y: globalSelectedRect.maxY))

        let shapes = [left, top, right, bottom].map { path -> CAShapeLayer in
            let shape = CAShapeLayer()
            shape.bounds = mainView.bounds
            shape.position = mainView.center
            shape.lineWidth = 1
            shape.borderColor = styleManager.primaryColor.cgColor
            shape.strokeColor = styleManager.primaryColor.cgColor
            shape.path = path.cgPath
            shape.fillColor = UIColor.clear.cgColor
            shape.lineDashPattern = [3, 8]
            mainView.layer.addSublayer(shape)
            return shape
        }

        return shapes
    }

    func measurementPath(startPoint start: CGPoint, endPoint end: CGPoint) -> UIBezierPath {
        let vertical = start.y != end.y
        let padding: CGFloat = 3

        if vertical {
            let startLessThanEnd = start.y < end.y

            var start = start
            var end = end

            start.y += padding * (startLessThanEnd ? 1 : -1)
            end.y += padding * (startLessThanEnd ? -1 : 1)

            let path = UIBezierPath()
            path.move(to: CGPoint(x: start.x - 5, y: start.y))
            path.addLine(to: CGPoint(x: start.x + 5, y: start.y))
            path.addLine(to: CGPoint(x: start.x, y: start.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
            path.addLine(to: CGPoint(x: end.x - 5, y: end.y))
            path.addLine(to: CGPoint(x: end.x + 5, y: end.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
            path.addLine(to: CGPoint(x: start.x, y: start.y))

            return path
        } else {
            let startLessThanEnd = start.x < end.x

            var start = start
            var end = end

            start.x += padding * (startLessThanEnd ? 1 : -1)
            end.x += padding * (startLessThanEnd ? -1 : 1)

            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x, y: start.y - 5))
            path.addLine(to: CGPoint(x: start.x, y: start.y + 5))
            path.addLine(to: CGPoint(x: start.x, y: start.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y - 5))
            path.addLine(to: CGPoint(x: end.x, y: end.y + 5))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
            path.addLine(to: CGPoint(x: start.x, y: start.y))

            return path
        }
    }
}
