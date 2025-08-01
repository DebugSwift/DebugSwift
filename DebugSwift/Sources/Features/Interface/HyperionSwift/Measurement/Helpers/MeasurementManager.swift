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
        let globalSelectedRect = selectedView.superview?.convert(selectedView.frame, to: view) ?? CGRect.zero
        let globalComparisonViewRect = comparisonView.superview?.convert(comparisonView.frame, to: view) ?? CGRect.zero

        let topSelectedView = CGPoint(x: globalSelectedRect.origin.x + globalSelectedRect.size.width / 2, y: globalSelectedRect.origin.y)

        if frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            let topCompareView = CGPoint(x: globalSelectedRect.origin.x + globalSelectedRect.size.width / 2, y: globalComparisonViewRect.origin.y)

            let topMeasurementPath = measurementFactory.measurementPath(startPoint: topSelectedView, endPoint: topCompareView)
            addShape(
                in: view,
                forPath: topMeasurementPath
            )

            let distance = abs(topCompareView.y - topSelectedView.y)
            let value = String(format: "%0.1fpt", distance)
            
            // Position label closer to measurement line
            let centerY = topSelectedView.y + (topCompareView.y - topSelectedView.y) / 2
            let centerX = topCompareView.x
            
            // For very top measurements, position label to the side
            let isNearTop = centerY < 100 // Arbitrary threshold for "near top"
            let offsetX: CGFloat = isNearTop ? 24 : (distance > 20 ? 0 : 12)
            
            addMeasureLabel(
                in: view,
                value: value, 
                center: CGPoint(x: centerX + offsetX, y: centerY)
            )

        } else if globalSelectedRect.origin.y >= globalComparisonViewRect.origin.y + globalComparisonViewRect.size.height {
            let belowCompareView = CGPoint(x: topSelectedView.x, y: globalComparisonViewRect.origin.y + globalComparisonViewRect.size.height)

            let topMeasurementPath = measurementFactory.measurementPath(startPoint: topSelectedView, endPoint: belowCompareView)
            addShape(
                in: view,
                forPath: topMeasurementPath
            )

            let distance = abs(belowCompareView.y - topSelectedView.y)
            let value = String(format: "%0.1fpt", distance)
            let centerY = topSelectedView.y + (belowCompareView.y - topSelectedView.y) / 2
            let centerX = belowCompareView.x
            
            // For very top measurements, position label to the side
            let isNearTop = centerY < 100
            let offsetX: CGFloat = isNearTop ? 24 : (distance > 20 ? 0 : 12)
            
            addMeasureLabel(
                in: view,
                value: value, 
                center: CGPoint(x: centerX + offsetX, y: centerY)
            )
        }
    }

    func placeBottomMeasurementBetweenSelectedView(in view: UIView, _ selectedView: UIView, comparisonView: UIView) {
        let globalSelectedRect = selectedView.superview?.convert(selectedView.frame, to: view) ?? CGRect.zero
        let globalComparisonViewRect = comparisonView.superview?.convert(comparisonView.frame, to: view) ?? CGRect.zero

        let belowSelectedView = CGPoint(x: globalSelectedRect.origin.x + (globalSelectedRect.size.width / 2), y: globalSelectedRect.origin.y + globalSelectedRect.size.height)

        if frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            let comparisonBottom = CGPoint(x: belowSelectedView.x, y: globalComparisonViewRect.origin.y + globalComparisonViewRect.size.height)

            let bottomMeasurementPath = measurementFactory.measurementPath(startPoint: belowSelectedView, endPoint: comparisonBottom)
            addShape(
                in: view,
                forPath: bottomMeasurementPath
            )

            let distance = abs(belowSelectedView.y - comparisonBottom.y)
            let value = String(format: "%0.1fpt", distance)
            let centerY = belowSelectedView.y + ((comparisonBottom.y - belowSelectedView.y) / 2)
            let centerX = comparisonBottom.x
            
            // Smaller offset to keep labels closer
            let offsetX: CGFloat = distance > 20 ? 0 : 12
            
            addMeasureLabel(
                in: view,
                value: value, 
                center: CGPoint(x: centerX + offsetX, y: centerY)
            )
        } else if belowSelectedView.y <= globalComparisonViewRect.origin.y {
            let comparisonTop = CGPoint(x: belowSelectedView.x, y: globalComparisonViewRect.origin.y)
            let bottomMeasurementPath = measurementFactory.measurementPath(startPoint: belowSelectedView, endPoint: comparisonTop)
            addShape(
                in: view,
                forPath: bottomMeasurementPath
            )

            let distance = abs(belowSelectedView.y - comparisonTop.y)
            let value = String(format: "%0.1fpt", distance)
            let centerY = belowSelectedView.y + ((comparisonTop.y - belowSelectedView.y) / 2)
            let centerX = comparisonTop.x
            
            // Smaller offset to keep labels closer
            let offsetX: CGFloat = distance > 20 ? 0 : 12
            
            addMeasureLabel(
                in: view,
                value: value, 
                center: CGPoint(x: centerX + offsetX, y: centerY)
            )
        }
    }

    func placeLeftMeasurementBetweenSelectedView(in view: UIView, _ selectedView: UIView, comparisonView: UIView) {
        let globalSelectedRect = selectedView.superview?.convert(selectedView.frame, to: view) ?? CGRect.zero
        let globalComparisonViewRect = comparisonView.superview?.convert(comparisonView.frame, to: view) ?? CGRect.zero

        let leftSelectedView = CGPoint(x: globalSelectedRect.origin.x, y: globalSelectedRect.origin.y + globalSelectedRect.size.height / 2)

        if frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            let leftCompareView = CGPoint(x: globalComparisonViewRect.origin.x, y: leftSelectedView.y)

            let leftMeasurementPath = measurementFactory.measurementPath(startPoint: leftSelectedView, endPoint: leftCompareView)
            addShape(
                in: view,
                forPath: leftMeasurementPath
            )

            let distance = abs(leftSelectedView.x - leftCompareView.x)
            let value = String(format: "%0.1fpt", distance)
            let centerX = leftCompareView.x + (leftSelectedView.x - leftCompareView.x) / 2
            let centerY = leftCompareView.y
            
            // Smaller offset to keep labels closer
            let offsetY: CGFloat = distance > 20 ? 0 : -12 // Reduced from -20 to -12
            
            addMeasureLabel(
                in: view,
                value: value,
                center: CGPoint(x: centerX, y: centerY + offsetY)
            )
        } else if leftSelectedView.x >= globalComparisonViewRect.origin.x + globalComparisonViewRect.size.width {
            let rightCompareView = CGPoint(x: globalComparisonViewRect.origin.x + globalComparisonViewRect.size.width, y: leftSelectedView.y)

            let leftMeasurementPath = measurementFactory.measurementPath(startPoint: leftSelectedView, endPoint: rightCompareView)
            addShape(
                in: view,
                forPath: leftMeasurementPath
            )

            let distance = abs(leftSelectedView.x - rightCompareView.x)
            let value = String(format: "%0.1fpt", distance)
            let centerX = rightCompareView.x + (leftSelectedView.x - rightCompareView.x) / 2
            let centerY = rightCompareView.y
            
            // Smaller offset to keep labels closer
            let offsetY: CGFloat = distance > 20 ? 0 : -12
            
            addMeasureLabel(
                in: view,
                value: value,
                center: CGPoint(x: centerX, y: centerY + offsetY)
            )
        }
    }

    func placeRightMeasurementBetweenSelectedView(in view: UIView, _ selectedView: UIView, comparisonView: UIView) {        
        let globalSelectedRect = selectedView.superview?.convert(selectedView.frame, to: view) ?? CGRect.zero
        let globalComparisonViewRect = comparisonView.superview?.convert(comparisonView.frame, to: view) ?? CGRect.zero

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

            let distance = abs(rightSelectedView.x - leftCompareView.x)
            let value = String(format: "%0.1fpt", distance)
            let centerX = rightSelectedView.x + (leftCompareView.x - rightSelectedView.x) / 2
            let centerY = leftCompareView.y
            
            // Smaller offset to keep labels closer
            let offsetY: CGFloat = distance > 20 ? 0 : -12
            
            addMeasureLabel(
                in: view,
                value: value,
                center: CGPoint(x: centerX, y: centerY + offsetY)
            )
        } else if rightSelectedView.x <= globalComparisonViewRect.origin.x {
            let leftGlobalView = CGPoint(x: globalComparisonViewRect.origin.x, y: rightSelectedView.y)

            let leftMeasurementPath = measurementFactory.measurementPath(startPoint: rightSelectedView, endPoint: leftGlobalView)
            addShape(
                in: view,
                forPath: leftMeasurementPath
            )

            let distance = abs(rightSelectedView.x - leftGlobalView.x)
            let value = String(format: "%0.1fpt", distance)
            let centerX = rightSelectedView.x + (leftGlobalView.x - rightSelectedView.x) / 2
            let centerY = leftGlobalView.y
            
            // Smaller offset to keep labels closer
            let offsetY: CGFloat = distance > 20 ? 0 : -12
            
            addMeasureLabel(
                in: view,
                value: value,
                center: CGPoint(x: centerX, y: centerY + offsetY)
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

        // Calculate the label size to ensure it fits within bounds
        let labelSize = label.frame.size
        let standardPadding: CGFloat = 8  // Standard padding from edges
        let topPadding: CGFloat = 64      // Extra padding for navigation bar area
        
        // Clamp the center position to keep the label visible
        var adjustedCenter = center
        
        // Clamp X coordinate
        let minX = labelSize.width / 2 + standardPadding
        let maxX = view.bounds.width - labelSize.width / 2 - standardPadding
        adjustedCenter.x = max(minX, min(maxX, center.x))
        
        // Clamp Y coordinate with extra top padding
        let minY = max(labelSize.height / 2 + topPadding, labelSize.height / 2 + standardPadding)
        let maxY = view.bounds.height - labelSize.height / 2 - standardPadding
        adjustedCenter.y = max(minY, min(maxY, center.y))
        
        measurementsContainer.center = adjustedCenter
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
        shapeLayer.lineWidth = 0.8
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
