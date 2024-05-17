//
//  ChartView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class ChartView: UIView {
    var measurements: [CGFloat] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    var maxValue: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var chartColor: UIColor = .blue {
        didSet {
            setNeedsDisplay()
        }
    }

    var axisColor: UIColor = Theme.shared.fontColor {
        didSet {
            setNeedsDisplay()
        }
    }

    var filled = true {
        didSet {
            setNeedsDisplay()
        }
    }

    var markedValue: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var markedValueFormat = "%.1lf" {
        didSet {
            setNeedsDisplay()
        }
    }

    var measurementsLimit = 1 {
        didSet {
            setNeedsDisplay()
        }
    }

    var measurementInterval: TimeInterval = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var markedTimesInterval: TimeInterval = 20.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var graphHeight: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var topPadding: CGFloat = 20.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Clear previous drawings
        context.clear(rect)

        context.setFillColor(Theme.shared.backgroundColor.cgColor)
        context.fill(rect)

        // Set up coordinate system
        let xAxisHeight: CGFloat = 30.0
        let yAxisWidth: CGFloat = 30.0
        let graphRect = CGRect(
            x: yAxisWidth, y: topPadding, width: rect.width - yAxisWidth,
            height: graphHeight - xAxisHeight
        )

        // Draw the x-axis
        drawXAxis(in: context, graphRect: graphRect)

        // Draw the y-axis
        drawYAxis(in: context, graphRect: graphRect)

        // Draw the graph line
        drawGraphLine(in: context, graphRect: graphRect)

        // Mark a specific value on the graph
        markValueOnGraph(in: context, graphRect: graphRect)
    }

    private func drawXAxis(in context: CGContext, graphRect: CGRect) {
        context.setStrokeColor(axisColor.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: graphRect.minX, y: graphRect.maxY))
        context.addLine(to: CGPoint(x: graphRect.maxX, y: graphRect.maxY))
        context.strokePath()
    }

    private func drawYAxis(in context: CGContext, graphRect: CGRect) {
        context.move(to: CGPoint(x: graphRect.minX, y: graphRect.minY))
        context.addLine(to: CGPoint(x: graphRect.minX, y: graphRect.maxY))
        context.strokePath()
    }

    private func drawGraphLine(in _: CGContext, graphRect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = 2.0
        path.lineJoinStyle = .round
        path.lineCapStyle = .round

        let xStep = graphRect.width / CGFloat(measurements.count - 1)
        let yScale = graphRect.height / maxValue

        for (index, value) in measurements.enumerated() {
            let x = graphRect.minX + CGFloat(index) * xStep
            let y = graphRect.maxY - value * yScale

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        if filled, measurements.count > 1 {
            path.addLine(to: CGPoint(x: graphRect.maxX, y: graphRect.maxY))
            path.addLine(to: CGPoint(x: graphRect.minX, y: graphRect.maxY))
            path.close()

            let fillPath = UIBezierPath(
                rect: CGRect(
                    x: graphRect.minX,
                    y: graphRect.minY,
                    width: graphRect.width,
                    height: graphRect.height
                )
            )
            fillPath.append(path)
            fillPath.usesEvenOddFillRule = true

            UIColor.clear.setFill()
            fillPath.fill()
        }

        chartColor.setStroke()
        path.stroke()
    }

    private func markValueOnGraph(in context: CGContext, graphRect: CGRect) {
        if let index = measurements.firstIndex(of: markedValue) {
            let x = graphRect.minX + CGFloat(index) * (graphRect.width / CGFloat(measurements.count - 1))
            let y = graphRect.maxY - markedValue * (graphRect.height / maxValue)

            let markPath = UIBezierPath(
                arcCenter: CGPoint(x: x, y: y), radius: 5.0, startAngle: 0, endAngle: CGFloat.pi * 2,
                clockwise: true
            )
            markPath.fill()

            // Draw Y-axis line only up to the top of the graph
            context.move(to: CGPoint(x: x, y: y))
            context.addLine(to: CGPoint(x: x, y: graphRect.minY))
            context.setStrokeColor(Theme.shared.fontColor.cgColor)
            context.setLineWidth(1.0)
            context.strokePath()

            let formattedText = String(format: markedValueFormat, markedValue)
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: Theme.shared.fontColor,
                .font: UIFont.systemFont(ofSize: 12)
            ]
            let textSize = formattedText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: x - textSize.width / 2, y: y - 20, width: textSize.width, height: textSize.height
            )
            formattedText.draw(in: textRect, withAttributes: attributes)
        }
    }
}
