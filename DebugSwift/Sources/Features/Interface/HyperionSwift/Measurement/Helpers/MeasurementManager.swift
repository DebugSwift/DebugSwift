//
//  MeasurementManager.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import Foundation
import UIKit

@MainActor
class MeasurementManager {
    private var measurementViews: [UIView] = []
    private var selectedViewsStyling: [CAShapeLayer] = []
    private var compareViewStyling: [CAShapeLayer] = []

    private let delegate: MeasurementViewDelegate?
    private let styleManager: StyleManager
    private let measurementFactory: MeasurementElementsFactory

    init(
        delegate: MeasurementViewDelegate?,
        measurementFactory: MeasurementElementsFactory,
        styleManager: StyleManager
    ) {
        self.delegate = delegate
        self.styleManager = styleManager
        self.measurementFactory = measurementFactory
    }

    func setup() {
        measurementViews = []
        compareViewStyling = []
        selectedViewsStyling = []
    }

    func reset() {
        setup()
        delegate?.attachedWindow?.layer.sublayers?.removeAll()
    }

    func frame(_ rect1: CGRect?, insideFrame rect2: CGRect?) -> Bool {
        guard let rect1 = rect1, let rect2 = rect2 else { return false }
        return rect2.contains(rect1)
    }

    func addBorder(in view: UIView, forSelected selectedView: UIView?) {
        guard
            let selectedView,
            let attachedWindow = delegate?.attachedWindow
        else {
            reset()
            return
        }

        let shape = measurementFactory.setPath(in: view, for: selectedView, with: attachedWindow)
        selectedViewsStyling.append(shape)

        let lines = measurementFactory.setLines(in: view, for: selectedView, with: attachedWindow)
        selectedViewsStyling.append(contentsOf: lines)
    }

    func addBorder(in view: UIView, forCompare compareView: UIView?) {
        guard
            let compareView,
            let attachedWindow = delegate?.attachedWindow
        else {
            reset()
            return
        }

        let shape = measurementFactory.setPath(in: view, forCompare: compareView, with: attachedWindow)
        compareViewStyling.append(shape)
    }

    func placeTopMeasurementBetweenSelectedView(in view: UIView, _ selectedView: UIView, comparisonView: UIView) {
        guard let attachedWindow = delegate?.attachedWindow else {
            reset()
            return
        }

        let globalSelectedRect = selectedView.superview!.convert(selectedView.frame, to: attachedWindow)
        let globalComparisonViewRect = comparisonView.superview!.convert(comparisonView.frame, to: attachedWindow)

        let topSelectedView = CGPoint(x: globalSelectedRect.origin.x + globalSelectedRect.size.width / 2, y: globalSelectedRect.origin.y)

        if frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            let topCompareView = CGPoint(x: globalSelectedRect.origin.x + globalSelectedRect.size.width / 2, y: globalComparisonViewRect.origin.y)

            let topMeasurementPath = measurementFactory.measurementPath(startPoint: topSelectedView, endPoint: topCompareView)
            addShape(
                in: view,
                forPath: topMeasurementPath
            )

            let value = String(format: "%0.1fpt", abs(topCompareView.y - topSelectedView.y))
            let center = CGPoint(x: topCompareView.x, y: topSelectedView.y + (topCompareView.y - topSelectedView.y) / 2)
            addMeasureLabel(
                in: view,
                value: value, center: center
            )

        } else if globalSelectedRect.origin.y >= globalComparisonViewRect.origin.y + globalComparisonViewRect.size.height {
            let belowCompareView = CGPoint(x: topSelectedView.x, y: globalComparisonViewRect.origin.y + globalComparisonViewRect.size.height)

            let topMeasurementPath = measurementFactory.measurementPath(startPoint: topSelectedView, endPoint: belowCompareView)
            addShape(
                in: view,
                forPath: topMeasurementPath
            )

            let value = String(format: "%0.1fpt", abs(belowCompareView.y - topSelectedView.y))
            let center = CGPoint(x: belowCompareView.x, y: topSelectedView.y + (belowCompareView.y - topSelectedView.y) / 2)
            addMeasureLabel(
                in: view,
                value: value, center: center
            )
        }
    }

    func placeBottomMeasurementBetweenSelectedView(in view: UIView, _ selectedView: UIView, comparisonView: UIView) {
        guard let attachedWindow = delegate?.attachedWindow else {
            reset()
            return
        }

        let globalSelectedRect = selectedView.superview!.convert(selectedView.frame, to: attachedWindow)
        let globalComparisonViewRect = comparisonView.superview!.convert(comparisonView.frame, to: attachedWindow)

        let belowSelectedView = CGPoint(x: globalSelectedRect.origin.x + (globalSelectedRect.size.width / 2), y: globalSelectedRect.origin.y + globalSelectedRect.size.height)

        if frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            let comparisonBottom = CGPoint(x: belowSelectedView.x, y: globalComparisonViewRect.origin.y + globalComparisonViewRect.size.height)

            let bottomMeasurementPath = measurementFactory.measurementPath(startPoint: belowSelectedView, endPoint: comparisonBottom)
            addShape(
                in: view,
                forPath: bottomMeasurementPath
            )

            addMeasureLabel(
                in: view,
                value: String(format: "%0.1fpt", abs(belowSelectedView.y - comparisonBottom.y)), center: CGPoint(x: comparisonBottom.x, y: belowSelectedView.y + ((comparisonBottom.y - belowSelectedView.y) / 2))
            )
        } else if belowSelectedView.y <= globalComparisonViewRect.origin.y {
            let comparisonTop = CGPoint(x: belowSelectedView.x, y: globalComparisonViewRect.origin.y)
            let bottomMeasurementPath = measurementFactory.measurementPath(startPoint: belowSelectedView, endPoint: comparisonTop)
            addShape(
                in: view,
                forPath: bottomMeasurementPath
            )

            addMeasureLabel(
                in: view,
                value: String(format: "%0.1fpt", abs(belowSelectedView.y - comparisonTop.y)), center: CGPoint(x: comparisonTop.x, y: belowSelectedView.y + ((comparisonTop.y - belowSelectedView.y) / 2))
            )
        }
    }

    func placeLeftMeasurementBetweenSelectedView(in view: UIView, _ selectedView: UIView, comparisonView: UIView) {
        guard let attachedWindow = delegate?.attachedWindow else {
            reset()
            return
        }

        let globalSelectedRect = selectedView.superview!.convert(selectedView.frame, to: attachedWindow)
        let globalComparisonViewRect = comparisonView.superview!.convert(comparisonView.frame, to: attachedWindow)

        let leftSelectedView = CGPoint(x: globalSelectedRect.origin.x, y: globalSelectedRect.origin.y + globalSelectedRect.size.height / 2)

        if frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            let leftCompareView = CGPoint(x: globalComparisonViewRect.origin.x, y: leftSelectedView.y)

            let leftMeasurementPath = measurementFactory.measurementPath(startPoint: leftSelectedView, endPoint: leftCompareView)
            addShape(
                in: view,
                forPath: leftMeasurementPath
            )

            addMeasureLabel(
                in: view,
                value: String(format: "%0.1fpt", abs(leftSelectedView.x - leftCompareView.x)),
                center: CGPoint(x: leftCompareView.x + (leftSelectedView.x - leftCompareView.x) / 2, y: leftCompareView.y)
            )
        } else if leftSelectedView.x >= globalComparisonViewRect.origin.x + globalComparisonViewRect.size.width {
            let rightCompareView = CGPoint(x: globalComparisonViewRect.origin.x + globalComparisonViewRect.size.width, y: leftSelectedView.y)

            let leftMeasurementPath = measurementFactory.measurementPath(startPoint: leftSelectedView, endPoint: rightCompareView)
            addShape(
                in: view,
                forPath: leftMeasurementPath
            )

            addMeasureLabel(
                in: view,
                value: String(format: "%0.1fpt", abs(leftSelectedView.x - rightCompareView.x)),
                center: CGPoint(x: rightCompareView.x + (leftSelectedView.x - rightCompareView.x) / 2, y: rightCompareView.y)
            )
        }
    }

    func placeRightMeasurementBetweenSelectedView(in view: UIView, _ selectedView: UIView, comparisonView: UIView) {
        guard let attachedWindow = delegate?.attachedWindow else {
            reset()
            return
        }
        let globalSelectedRect = selectedView.superview!.convert(selectedView.frame, to: attachedWindow)
        let globalComparisonViewRect = comparisonView.superview!.convert(comparisonView.frame, to: attachedWindow)

        let rightSelectedView = CGPoint(x: globalSelectedRect.origin.x + globalSelectedRect.size.width, y: globalSelectedRect.origin.y + globalSelectedRect.size.height / 2)

        if frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            let leftCompareView = CGPoint(
                x: globalComparisonViewRect.origin.x + globalComparisonViewRect.size.width,
                y: rightSelectedView.y
            )

            let leftMeasurementPath = measurementFactory.measurementPath(startPoint: rightSelectedView, endPoint: leftCompareView)
            addShape(
                in: view,
                forPath: leftMeasurementPath
            )

            addMeasureLabel(
                in: view,
                value: String(format: "%0.1fpt", abs(rightSelectedView.x - leftCompareView.x)),
                center: CGPoint(x: rightSelectedView.x + (leftCompareView.x - rightSelectedView.x) / 2, y: leftCompareView.y)
            )
        } else if rightSelectedView.x <= globalComparisonViewRect.origin.x {
            let leftGlobalView = CGPoint(x: globalComparisonViewRect.origin.x, y: rightSelectedView.y)

            let leftMeasurementPath = measurementFactory.measurementPath(startPoint: rightSelectedView, endPoint: leftGlobalView)
            addShape(
                in: view,
                forPath: leftMeasurementPath
            )

            addMeasureLabel(
                in: view,
                value: String(format: "%0.1fpt", abs(rightSelectedView.x - leftGlobalView.x)),
                center: CGPoint(x: rightSelectedView.x + (leftGlobalView.x - rightSelectedView.x) / 2, y: leftGlobalView.y)
            )
        }
    }

    func addMeasureLabel(in view: UIView, value: String, center: CGPoint) {
        guard delegate?.attachedWindow != nil else {
            reset()
            return
        }

        let measurementsContainer = UIView()
        measurementsContainer.translatesAutoresizingMaskIntoConstraints = false
        let label = measurementFactory.createMeasurementLabel(withText: value)
        measurementsContainer.addSubview(label)

        measurementsContainer.center = center
        measurementViews.append(measurementsContainer)

        view.addSubview(measurementsContainer)
    }

    func addShape(in view: UIView, forPath path: UIBezierPath) {
        guard delegate?.attachedWindow != nil else {
            reset()
            return
        }

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = styleManager.primaryColor.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clear.cgColor

        compareViewStyling.append(shapeLayer)
        view.layer.addSublayer(shapeLayer)
    }

    // Clean

    func clearAllStyling() {
        clearMeasurementViews()
        clearSelectedStyling()
        clearCompareStyling()
    }

    func clearMeasurementViews() {
        for view in measurementViews {
            view.removeFromSuperview()
        }
        measurementViews.removeAll()
    }

    func clearSelectedStyling() {
        for shape in selectedViewsStyling {
            shape.removeFromSuperlayer()
        }
        selectedViewsStyling.removeAll()
    }

    func clearCompareStyling() {
        for shape in compareViewStyling {
            shape.removeFromSuperlayer()
        }
        compareViewStyling.removeAll()
    }
}
