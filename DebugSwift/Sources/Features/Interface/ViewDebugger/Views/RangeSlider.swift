// https://github.com/warchimede/RangeSlider

import QuartzCore
import UIKit

final class RangeSliderTrackLayer: CALayer, @unchecked Sendable {
    weak var rangeSlider: RangeSlider?
    
    // Cached values from RangeSlider to avoid accessing MainActor properties in draw
    var curvaceousness: CGFloat = 0.3
    var trackTintColor = UIColor(white: 0.9, alpha: 1.0)
    var trackHighlightTintColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0)
    var lowerValuePosition: CGFloat = 0
    var upperValuePosition: CGFloat = 0

    override func draw(in ctx: CGContext) {
        let cornerRadius = bounds.height * curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)

        ctx.setFillColor(trackTintColor.cgColor)
        ctx.fillPath()

        ctx.setFillColor(trackHighlightTintColor.cgColor)
        let rect = CGRect(x: lowerValuePosition, y: 0.0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
        ctx.fill(rect)
    }
}

final class RangeSliderThumbLayer: CALayer, @unchecked Sendable {
    var highlighted = false {
        didSet {
            setNeedsDisplay()
        }
    }

    weak var rangeSlider: RangeSlider?
    
    // Cached values from RangeSlider
    var curvaceousness: CGFloat = 0.3
    var thumbTintColor = UIColor.white

    var strokeColor = UIColor.lightGray {
        didSet {
            setNeedsDisplay()
        }
    }

    var lineWidth: CGFloat = 0.3 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(in ctx: CGContext) {
        let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
        let cornerRadius = thumbFrame.height * curvaceousness / 2.0
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)

        ctx.setFillColor(thumbTintColor.cgColor)
        ctx.addPath(thumbPath.cgPath)
        ctx.fillPath()

        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(thumbPath.cgPath)
        ctx.strokePath()

        if highlighted {
            ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
            ctx.addPath(thumbPath.cgPath)
            ctx.fillPath()
        }
    }
}

final class RangeSlider: UIControl {
    var minimumValue = 0.0 {
        willSet(newValue) {
            assert(newValue < maximumValue, "RangeSlider: minimumValue should be lower than maximumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }

    var maximumValue = 1.0 {
        willSet(newValue) {
            assert(newValue > minimumValue, "RangeSlider: maximumValue should be greater than minimumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }

    var lowerValue = 0.2 {
        didSet {
            if lowerValue < minimumValue {
                lowerValue = minimumValue
            }
            updateLayerFrames()
        }
    }

    var upperValue = 0.8 {
        didSet {
            if upperValue > maximumValue {
                upperValue = maximumValue
            }
            updateLayerFrames()
        }
    }

    var gapBetweenThumbs: Double {
        0.5 * Double(thumbWidth) * (maximumValue - minimumValue) / Double(bounds.width)
    }

    var trackTintColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayer.trackTintColor = trackTintColor
            trackLayer.setNeedsDisplay()
        }
    }

    var trackHighlightTintColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            trackLayer.trackHighlightTintColor = trackHighlightTintColor
            trackLayer.setNeedsDisplay()
        }
    }

    var thumbTintColor = UIColor.white {
        didSet {
            lowerThumbLayer.thumbTintColor = thumbTintColor
            upperThumbLayer.thumbTintColor = thumbTintColor
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    var thumbBorderColor = UIColor.lightGray {
        didSet {
            lowerThumbLayer.strokeColor = thumbBorderColor
            upperThumbLayer.strokeColor = thumbBorderColor
        }
    }

    var thumbBorderWidth: CGFloat = 0.1 {
        didSet {
            lowerThumbLayer.lineWidth = thumbBorderWidth
            upperThumbLayer.lineWidth = thumbBorderWidth
        }
    }

    var curvaceousness: CGFloat = 0.3 {
        didSet {
            if curvaceousness < 0.0 {
                curvaceousness = 0.0
            }

            if curvaceousness > 1.0 {
                curvaceousness = 1.0
            }

            trackLayer.curvaceousness = curvaceousness
            lowerThumbLayer.curvaceousness = curvaceousness
            upperThumbLayer.curvaceousness = curvaceousness
            trackLayer.setNeedsDisplay()
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    fileprivate var previouslocation = CGPoint()

    fileprivate let trackLayer = RangeSliderTrackLayer()
    fileprivate let lowerThumbLayer = RangeSliderThumbLayer()
    fileprivate let upperThumbLayer = RangeSliderThumbLayer()

    fileprivate var thumbWidth: CGFloat {
        CGFloat(bounds.height)
    }

    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
    }

    override func layoutSublayers(of _: CALayer) {
        super.layoutSublayers(of: layer)
        updateLayerFrames()
    }

    fileprivate func initializeLayers() {
        layer.backgroundColor = UIColor.clear.cgColor

        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        trackLayer.trackTintColor = trackTintColor
        trackLayer.trackHighlightTintColor = trackHighlightTintColor
        trackLayer.curvaceousness = curvaceousness
        layer.addSublayer(trackLayer)

        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        lowerThumbLayer.thumbTintColor = thumbTintColor
        lowerThumbLayer.curvaceousness = curvaceousness
        layer.addSublayer(lowerThumbLayer)

        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.main.scale
        upperThumbLayer.thumbTintColor = thumbTintColor
        upperThumbLayer.curvaceousness = curvaceousness
        layer.addSublayer(upperThumbLayer)
    }

    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height / 2.3)
        
        let lowerPosition = CGFloat(positionForValue(lowerValue))
        let upperPosition = CGFloat(positionForValue(upperValue))
        trackLayer.lowerValuePosition = lowerPosition
        trackLayer.upperValuePosition = upperPosition
        trackLayer.setNeedsDisplay()

        let lowerThumbCenter = lowerPosition
        lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        lowerThumbLayer.setNeedsDisplay()

        let upperThumbCenter = upperPosition
        upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        upperThumbLayer.setNeedsDisplay()

        CATransaction.commit()
    }

    func positionForValue(_ value: Double) -> Double {
        Double(bounds.width - thumbWidth) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbWidth / 2.0)
    }

    func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        min(max(value, lowerValue), upperValue)
    }

    // MARK: - Touches

    override func beginTracking(_ touch: UITouch, with _: UIEvent?) -> Bool {
        previouslocation = touch.location(in: self)

        // Hit test the thumb layers
        if lowerThumbLayer.frame.contains(previouslocation) {
            lowerThumbLayer.highlighted = true
        } else if upperThumbLayer.frame.contains(previouslocation) {
            upperThumbLayer.highlighted = true
        }

        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }

    override func continueTracking(_ touch: UITouch, with _: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        // Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previouslocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)

        previouslocation = location

        // Update the values
        if lowerThumbLayer.highlighted {
            lowerValue = boundValue(lowerValue + deltaValue, toLowerValue: minimumValue, upperValue: upperValue - gapBetweenThumbs)
        } else if upperThumbLayer.highlighted {
            upperValue = boundValue(upperValue + deltaValue, toLowerValue: lowerValue + gapBetweenThumbs, upperValue: maximumValue)
        }

        sendActions(for: .valueChanged)

        return true
    }

    override func endTracking(_: UITouch?, with _: UIEvent?) {
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
    }
}
