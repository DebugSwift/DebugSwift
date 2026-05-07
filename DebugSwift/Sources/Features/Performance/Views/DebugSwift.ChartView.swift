//
//  ChartView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class ChartView: UIView {
    
    // MARK: - Public Properties
    
    var measurements: [CGFloat] = [] {
        didSet {
            animateDataUpdate()
        }
    }

    var maxValue: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var chartColor: UIColor = .systemBlue {
        didSet {
            updateGradientColors()
            setNeedsDisplay()
        }
    }

    var axisColor: UIColor = .systemGray3 {
        didSet {
            setNeedsDisplay()
        }
    }

    var gridColor: UIColor = .systemGray5 {
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

    var topPadding: CGFloat = 30.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Private Properties
    
    private var gradientLayer: CAGradientLayer?
    private var animationProgress: CGFloat = 1.0
    private var previousMeasurements: [CGFloat] = []
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.clear
        isOpaque = false
        // Removed gradient layer setup since we're using Core Graphics now
    }
    
    private func updateGradientColors() {
        // No longer needed since we're using Core Graphics gradients
        setNeedsDisplay()
    }
    
    private func createGradientLayer() -> CAGradientLayer {
        // This method is no longer used but kept for compatibility
        let gradient = CAGradientLayer()
        return gradient
    }
    
    // MARK: - Animation
    
    private func animateDataUpdate() {
        guard !measurements.isEmpty else {
            setNeedsDisplay()
            return
        }
        
        // Don't animate if this is the first data or if we don't have previous data
        if previousMeasurements.isEmpty || previousMeasurements.count != measurements.count {
            previousMeasurements = measurements
            animationProgress = 1.0
            setNeedsDisplay()
            return
        }
        
        // Only animate if there's actually a change in data
        let hasChanges = zip(previousMeasurements, measurements).contains { $0.0 != $0.1 }
        if !hasChanges {
            setNeedsDisplay()
            return
        }
        
        animationProgress = 0.0
        
        // Use a more precise timer for smoother animation
        let displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink.add(to: .main, forMode: .common)
        
        // Store the display link to invalidate it later
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            displayLink.invalidate()
            self.animationProgress = 1.0
            self.previousMeasurements = self.measurements
            self.setNeedsDisplay()
        }
    }
    
    @objc private func updateAnimation() {
        animationProgress = min(animationProgress + 0.08, 1.0) // Faster, smoother animation
        setNeedsDisplay()
    }

    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Clear and set background
        context.clear(rect)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)

        // Calculate graph dimensions
        let xAxisHeight: CGFloat = 40.0
        let yAxisWidth: CGFloat = 50.0
        let graphRect = CGRect(
            x: yAxisWidth,
            y: topPadding,
            width: rect.width - yAxisWidth - 10,
            height: graphHeight - xAxisHeight - topPadding
        )
        
        // Only show configurable time window of data
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        
        guard !measurementsToShow.isEmpty && graphRect.width > 0 && graphRect.height > 0 else {
            drawEmptyState(in: context, rect: rect)
            return
        }

        // Draw grid
        drawGrid(in: context, graphRect: graphRect)
        
        // Draw axes
        drawAxes(in: context, graphRect: graphRect)
        
        // Draw y-axis labels
        drawYAxisLabels(in: context, graphRect: graphRect)
        
        // Draw x-axis labels
        drawXAxisLabels(in: context, graphRect: graphRect)
        
        // Draw graph
        drawGraph(in: context, graphRect: graphRect)
        
        // Draw marked value
        drawMarkedValue(in: context, graphRect: graphRect)
        
        // Draw current value indicator
        drawCurrentValueIndicator(in: context, graphRect: graphRect)
    }
    
    private func drawEmptyState(in context: CGContext, rect: CGRect) {
        let emptyText = "No data available"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        let textSize = emptyText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        emptyText.draw(in: textRect, withAttributes: attributes)
    }
    
    private func drawGrid(in context: CGContext, graphRect: CGRect) {
        context.setStrokeColor(gridColor.cgColor)
        context.setLineWidth(0.5)
        context.setAlpha(0.3)
        
        // Horizontal grid lines
        let horizontalLines = 5
        for i in 0...horizontalLines {
            let y = graphRect.minY + (graphRect.height / CGFloat(horizontalLines)) * CGFloat(i)
            context.move(to: CGPoint(x: graphRect.minX, y: y))
            context.addLine(to: CGPoint(x: graphRect.maxX, y: y))
        }
        
        // Vertical grid lines - adjusted for configurable time window
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        let verticalLines = min(5, max(measurementsToShow.count - 1, 1)) // Show reasonable number of vertical lines
        
        if verticalLines > 0 {
            for i in 0...verticalLines {
                let x = graphRect.minX + (graphRect.width / CGFloat(verticalLines)) * CGFloat(i)
                context.move(to: CGPoint(x: x, y: graphRect.minY))
                context.addLine(to: CGPoint(x: x, y: graphRect.maxY))
            }
        }
        
        context.strokePath()
        context.setAlpha(1.0)
    }
    
    private func drawAxes(in context: CGContext, graphRect: CGRect) {
        context.setStrokeColor(axisColor.cgColor)
        context.setLineWidth(1.0)
        
        // X-axis
        context.move(to: CGPoint(x: graphRect.minX, y: graphRect.maxY))
        context.addLine(to: CGPoint(x: graphRect.maxX, y: graphRect.maxY))
        
        // Y-axis
        context.move(to: CGPoint(x: graphRect.minX, y: graphRect.minY))
        context.addLine(to: CGPoint(x: graphRect.minX, y: graphRect.maxY))
        
        context.strokePath()
    }
    
    private func drawYAxisLabels(in context: CGContext, graphRect: CGRect) {
        let labelCount = 5
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        ]
        
        for i in 0...labelCount {
            let value = (maxValue / CGFloat(labelCount)) * CGFloat(labelCount - i)
            let labelText = String(format: markedValueFormat, value)
            let y = graphRect.minY + (graphRect.height / CGFloat(labelCount)) * CGFloat(i)
            
            let textSize = labelText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: graphRect.minX - textSize.width - 8,
                y: y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            labelText.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func drawXAxisLabels(in context: CGContext, graphRect: CGRect) {
        guard measurements.count > 1 else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        ]
        
        // Show configurable time window, with time flowing left (oldest) to right (newest)
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let timePerMeasurement = measurementInterval
        
        // Calculate how many measurements we should show (max 2 minutes worth)
        let maxMeasurements = Int(maxTimeSeconds / timePerMeasurement)
        let measurementsToShow = min(measurements.count, maxMeasurements)
        
        // Only show time labels for the measurements we're displaying
        let labelCount = min(6, measurementsToShow) // Show max 6 time labels
        
        if labelCount > 1 {
            for i in 0..<labelCount {
                // Calculate the time for this position (0s to maxTimeSeconds)
                let timeValue = (Double(i) / Double(labelCount - 1)) * maxTimeSeconds
                
                // Format time labels dynamically based on time window
                let labelText: String
                if maxTimeSeconds <= 60 {
                    // For 1 minute or less, show only seconds
                    labelText = String(format: "%.0fs", timeValue)
                } else if maxTimeSeconds <= 600 {
                    // For 10 minutes or less, show seconds for < 60s, minutes for >= 60s
                    if timeValue < 60 {
                        labelText = String(format: "%.0fs", timeValue)
                    } else {
                        let minutes = timeValue / 60.0
                        labelText = String(format: "%.1fm", minutes)
                    }
                } else {
                    // For longer periods, always show minutes
                    let minutes = timeValue / 60.0
                    if minutes < 1 {
                        labelText = String(format: "%.0fs", timeValue)
                    } else if minutes < 10 {
                        labelText = String(format: "%.1fm", minutes)
                    } else {
                        labelText = String(format: "%.0fm", minutes)
                    }
                }
                
                // Position the label
                let x = graphRect.minX + (graphRect.width / CGFloat(labelCount - 1)) * CGFloat(i)
                let textSize = labelText.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: x - textSize.width / 2,
                    y: graphRect.maxY + 8,
                    width: textSize.width,
                    height: textSize.height
                )
                labelText.draw(in: textRect, withAttributes: attributes)
            }
        }
    }
    
    private func drawGraph(in context: CGContext, graphRect: CGRect) {
        // Only show configurable time window of data
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        
        guard measurementsToShow.count > 1 else {
            drawSinglePoint(in: context, graphRect: graphRect)
            return
        }
        
        let path = createGraphPath(graphRect: graphRect)
        
        // Draw filled area with gradient first (before the line)
        if filled {
            drawFilledArea(path: path, graphRect: graphRect)
        }
        
        // Draw line without shadow to avoid rendering issues
        drawGraphLine(path: path)
        
        // Draw data points
        drawDataPoints(in: context, graphRect: graphRect)
    }
    
    private func createGraphPath(graphRect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = 2.5
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        
        // Only show configurable time window of data
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        
        guard measurementsToShow.count > 0 else { return path }
        
        let xStep = graphRect.width / CGFloat(max(measurementsToShow.count - 1, 1))
        let yScale = graphRect.height / max(maxValue, 1.0)
        
        for (index, value) in measurementsToShow.enumerated() {
            // Interpolate between previous and current values for smooth animation
            let animatedValue: CGFloat
            let previousMeasurementsToShow = Array(previousMeasurements.suffix(maxMeasurements))
            if previousMeasurementsToShow.count > index && animationProgress < 1.0 {
                let previousValue = previousMeasurementsToShow[index]
                animatedValue = previousValue + (value - previousValue) * animationProgress
            } else {
                animatedValue = value
            }
            
            let x = graphRect.minX + CGFloat(index) * xStep
            let y = graphRect.maxY - animatedValue * yScale
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Add smooth curve instead of straight lines
                let previousIndex = index - 1
                let previousCurrentValue = measurementsToShow[previousIndex]
                let previousAnimatedValue: CGFloat
                if previousMeasurementsToShow.count > previousIndex && animationProgress < 1.0 {
                    let oldPreviousValue = previousMeasurementsToShow[previousIndex]
                    previousAnimatedValue = oldPreviousValue + (previousCurrentValue - oldPreviousValue) * animationProgress
                } else {
                    previousAnimatedValue = previousCurrentValue
                }
                
                let previousX = graphRect.minX + CGFloat(previousIndex) * xStep
                let previousY = graphRect.maxY - previousAnimatedValue * yScale
                
                let controlPoint1 = CGPoint(x: previousX + xStep * 0.5, y: previousY)
                let controlPoint2 = CGPoint(x: x - xStep * 0.5, y: y)
                
                path.addCurve(to: CGPoint(x: x, y: y),
                            controlPoint1: controlPoint1,
                            controlPoint2: controlPoint2)
            }
        }
        
        return path
    }
    
    private func drawFilledArea(path: UIBezierPath, graphRect: CGRect) {
        let fillPath = path.copy() as! UIBezierPath
        
        // Close the path to create filled area
        fillPath.addLine(to: CGPoint(x: graphRect.maxX, y: graphRect.maxY))
        fillPath.addLine(to: CGPoint(x: graphRect.minX, y: graphRect.maxY))
        fillPath.close()
        
        // Remove old gradient layer if it exists
        gradientLayer?.removeFromSuperlayer()
        
        // Create simple gradient fill using Core Graphics instead of CALayer
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        // Set clipping path
        fillPath.addClip()
        
        // Create gradient colors
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            chartColor.withAlphaComponent(0.3).cgColor,
            chartColor.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ] as CFArray
        
        let locations: [CGFloat] = [0.0, 0.6, 1.0]
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context?.drawLinearGradient(
                gradient,
                start: CGPoint(x: graphRect.midX, y: graphRect.minY),
                end: CGPoint(x: graphRect.midX, y: graphRect.maxY),
                options: []
            )
        }
        
        context?.restoreGState()
    }
    
    private func drawGraphLine(path: UIBezierPath) {
        // Draw clean line without shadow to avoid rendering artifacts
        chartColor.setStroke()
        path.lineWidth = 2.5
        path.stroke()
    }
    
    private func drawDataPoints(in context: CGContext, graphRect: CGRect) {
        // Only show configurable time window of data
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        
        guard measurementsToShow.count <= 20 else { return } // Only show points for smaller datasets
        
        let xStep = graphRect.width / CGFloat(max(measurementsToShow.count - 1, 1))
        let yScale = graphRect.height / max(maxValue, 1.0)
        
        for (index, value) in measurementsToShow.enumerated() {
            // Interpolate between previous and current values for smooth animation
            let animatedValue: CGFloat
            let previousMeasurementsToShow = Array(previousMeasurements.suffix(maxMeasurements))
            if previousMeasurementsToShow.count > index && animationProgress < 1.0 {
                let previousValue = previousMeasurementsToShow[index]
                animatedValue = previousValue + (value - previousValue) * animationProgress
            } else {
                animatedValue = value
            }
            
            let x = graphRect.minX + CGFloat(index) * xStep
            let y = graphRect.maxY - animatedValue * yScale
            
            // Draw outer circle
            context.setFillColor(chartColor.cgColor)
            context.fillEllipse(in: CGRect(x: x - 3, y: y - 3, width: 6, height: 6))
            
            // Draw inner circle
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3))
        }
    }
    
    private func drawSinglePoint(in context: CGContext, graphRect: CGRect) {
        // Only show configurable time window of data
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        
        guard let value = measurementsToShow.first else { return }
        
        let x = graphRect.minX + graphRect.width / 2
        let y = graphRect.maxY - (value / max(maxValue, 1.0)) * graphRect.height
        
        // Draw pulsing point for single value
        context.setFillColor(chartColor.cgColor)
        context.fillEllipse(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
        
        // Add value label
        let valueText = String(format: markedValueFormat, value)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        let textSize = valueText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: x - textSize.width / 2,
            y: y - textSize.height - 10,
            width: textSize.width,
            height: textSize.height
        )
        valueText.draw(in: textRect, withAttributes: attributes)
    }
    
    private func drawMarkedValue(in context: CGContext, graphRect: CGRect) {
        guard markedValue > 0 else { return }
        
        // Only show configurable time window of data
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        
        guard let maxIndex = measurementsToShow.firstIndex(of: markedValue) else { return }
        
        let xStep = graphRect.width / CGFloat(max(measurementsToShow.count - 1, 1))
        let x = graphRect.minX + CGFloat(maxIndex) * xStep
        let y = graphRect.maxY - (markedValue / max(maxValue, 1.0)) * graphRect.height
        
        // Draw vertical line to peak
        context.setStrokeColor(UIColor.systemYellow.cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x, y: graphRect.minY))
        context.strokePath()
        
        // Draw peak marker
        context.setFillColor(UIColor.systemYellow.cgColor)
        context.fillEllipse(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
        
        // Draw peak value label with background
        let peakText = String(format: markedValueFormat, markedValue)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        let textSize = peakText.size(withAttributes: attributes)
        let padding: CGFloat = 4
        let labelRect = CGRect(
            x: x - textSize.width / 2 - padding,
            y: y - textSize.height - 12,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )
        
        // Draw background
        context.setFillColor(UIColor.systemYellow.cgColor)
        context.fill(labelRect)
        context.addPath(UIBezierPath(roundedRect: labelRect, cornerRadius: 3).cgPath)
        context.fillPath()
        
        // Draw text
        let textRect = CGRect(
            x: x - textSize.width / 2,
            y: y - textSize.height - 10,
            width: textSize.width,
            height: textSize.height
        )
        peakText.draw(in: textRect, withAttributes: attributes)
    }
    
    private func drawCurrentValueIndicator(in context: CGContext, graphRect: CGRect) {
        guard let lastValue = measurements.last else { return }
        
        // Only show configurable time window of data
        let maxTimeSeconds = DebugSwift.Performance.Chart.timeWindowSeconds
        let maxMeasurements = Int(maxTimeSeconds / measurementInterval)
        let measurementsToShow = Array(measurements.suffix(maxMeasurements))
        
        guard measurementsToShow.count > 1 else { 
            // For single point, position in center
            let x = graphRect.minX + graphRect.width / 2
            let y = graphRect.maxY - (lastValue / max(maxValue, 1.0)) * graphRect.height
            drawCurrentValueAt(x: x, y: y, value: lastValue, graphRect: graphRect, context: context)
            return
        }
        
        // Position the indicator at the last data point
        let xStep = graphRect.width / CGFloat(measurementsToShow.count - 1)
        let x = graphRect.minX + CGFloat(measurementsToShow.count - 1) * xStep
        let y = graphRect.maxY - (lastValue / max(maxValue, 1.0)) * graphRect.height
        
        drawCurrentValueAt(x: x, y: y, value: lastValue, graphRect: graphRect, context: context)
    }
    
    private func drawCurrentValueAt(x: CGFloat, y: CGFloat, value: CGFloat, graphRect: CGRect, context: CGContext) {
        // Draw current value indicator with a larger, more visible circle
        context.setFillColor(chartColor.cgColor)
        context.fillEllipse(in: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
        
        // Draw inner highlight
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
        
        // Add current value label with background for better visibility
        let currentText = String(format: markedValueFormat, value)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        let textSize = currentText.size(withAttributes: attributes)
        let padding: CGFloat = 4
        
        // Position label above the point, with smart positioning to avoid clipping
        var labelX = x - textSize.width / 2
        var labelY = y - textSize.height - 15
        
        // Adjust position if it would go outside bounds
        if labelX < graphRect.minX {
            labelX = graphRect.minX
        } else if labelX + textSize.width > graphRect.maxX {
            labelX = graphRect.maxX - textSize.width
        }
        
        if labelY < graphRect.minY {
            labelY = y + 15 // Position below the point if no room above
        }
        
        let labelRect = CGRect(
            x: labelX - padding,
            y: labelY - padding / 2,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )
        
        // Draw background with rounded corners
        context.setFillColor(chartColor.withAlphaComponent(0.9).cgColor)
        context.addPath(UIBezierPath(roundedRect: labelRect, cornerRadius: 4).cgPath)
        context.fillPath()
        
        // Draw text
        let textRect = CGRect(
            x: labelX,
            y: labelY,
            width: textSize.width,
            height: textSize.height
        )
        currentText.draw(in: textRect, withAttributes: attributes)
    }
}

// MARK: - Extensions

extension UIBezierPath {
    func addSmoothCurve(to point: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        addCurve(to: point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }
}
