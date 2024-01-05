//
//  RangeSlider.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/2/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

/// A slider with two handles that allows for defining a range of values rather
/// than UISlider, which only allows for a single value.
final class RangeSlider: UIControl {
    private let trackImageView = UIImageView()
    private let fillImageView = UIImageView()
    private let leftHandleImageView = UIImageView()
    private let rightHandleImageView = UIImageView()
    
    private var isTrackingLeftHandle = false
    private var isTrackingRightHandle = false
    
    public var allowableMinimumValue: Float = 0.0 {
        didSet {
            if minimumValue < allowableMaximumValue {
                minimumValue = allowableMaximumValue
            }
            setNeedsLayout()
        }
    }
    
    public var allowableMaximumValue: Float = 1.0 {
        didSet {
            if maximumValue > allowableMaximumValue {
                maximumValue = allowableMaximumValue
            }
            setNeedsLayout()
        }
    }
    
    public var minimumValue: Float = 0.0 {
        didSet {
            sendActions(for: .valueChanged)
            setNeedsLayout()
        }
    }
    
    public var maximumValue: Float = 1.0 {
        didSet {
            sendActions(for: .valueChanged)
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        
        addSubview(fillImageView)
        addSubview(leftHandleImageView)
        addSubview(rightHandleImageView)
        
        configureTrackImageView()
        configureFillImageView()
        configureLeftHandleImageView()
        configureRightHandleImageView()
    }
    
    private func configureTrackImageView() {
        trackImageView.image = trackImage()
        trackImageView.isUserInteractionEnabled = false
        trackImageView.autoresizingMask = []
        addSubview(trackImageView)
    }
    
    private func configureFillImageView() {
        fillImageView.image = fillImage()
        fillImageView.isUserInteractionEnabled = false
        addSubview(fillImageView)
    }
    
    private func configureLeftHandleImageView() {
        leftHandleImageView.image = leftHandleImage()
        leftHandleImageView.isUserInteractionEnabled = false
        addSubview(leftHandleImageView)
    }
    
    private func configureRightHandleImageView() {
        rightHandleImageView.image = rightHandleImage()
        rightHandleImageView.isUserInteractionEnabled = false
        addSubview(rightHandleImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UIView
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: leftHandleImageView.image?.size.height ?? 0.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let leftHandleSize = leftHandleImageSize()
        let rightHandleSize = rightHandleImageSize()
        let trackSize = trackImageView.image?.size ?? .zero
        
        trackImageView.frame = CGRect(
            x: leftHandleSize.width / 2.0,
            y: bounds.midY - (trackSize.height / 2.0),
            width: bounds.width - (leftHandleSize.width / 2.0) - (rightHandleSize.width / 2.0),
            height: trackSize.height
        )
        
        let delta = allowableMaximumValue - allowableMinimumValue
        let minPercentage: Float
        let maxPercentage: Float
        if delta <= 0.0 {
            minPercentage = 0.0
            maxPercentage = 0.0
        } else {
            minPercentage = max(0.0, (minimumValue - allowableMinimumValue) / delta)
            maxPercentage = max(minPercentage, (maximumValue - allowableMinimumValue) / delta)
        }
        
        let sliderRangeWidth = bounds.width - leftHandleSize.width - rightHandleSize.width
        
        leftHandleImageView.frame = CGRect(
            x: roundToNearestPixel(sliderRangeWidth * CGFloat(minPercentage)),
            y: bounds.midY - (leftHandleSize.height / 2.0),
            width: leftHandleSize.width,
            height: leftHandleSize.height)
        
        rightHandleImageView.frame = CGRect(
            x: roundToNearestPixel(leftHandleSize.width + sliderRangeWidth * CGFloat(maxPercentage)),
            y: bounds.midY - (rightHandleSize.height / 2.0),
            width: rightHandleSize.width,
            height: rightHandleSize.height)
        
        fillImageView.frame = CGRect(
            x: leftHandleImageView.frame.midX,
            y: trackImageView.frame.minY,
            width: rightHandleImageView.frame.midX - leftHandleImageView.frame.midX,
            height: trackImageView.frame.height
        )
    }
    
    // MARK: UIControl
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        if leftHandleImageView.frame.contains(location) {
            isTrackingLeftHandle = true
            isTrackingRightHandle = false
            return true
        } else if rightHandleImageView.frame.contains(location) {
            isTrackingRightHandle = true
            isTrackingLeftHandle = false
            return true
        }
        return false
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        if isTrackingLeftHandle {
            minimumValue = min(max(allowableMinimumValue, valueAtX(location.x)), maximumValue)
            setNeedsLayout()
            layoutIfNeeded()
            return true
        } else if isTrackingRightHandle {
            maximumValue = max(min(allowableMaximumValue, valueAtX(location.x)), minimumValue)
            setNeedsLayout()
            layoutIfNeeded()
            return true
        }
        return false
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isTrackingLeftHandle = false
        isTrackingRightHandle = false
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        return false
    }
    
    // MARK: Private
    
    private func valueAtX(_ x: CGFloat) -> Float {
        let minX = leftHandleImageSize().width
        let maxX = bounds.width - rightHandleImageSize().width
        let cappedX = min(max(x, minX), maxX)
        let delta = maxX - minX
        return Float((delta > 0.0) ? (cappedX - minX) / delta : 0.0) * (allowableMaximumValue - allowableMinimumValue) + allowableMinimumValue
    }
    
    private func leftHandleImageSize() -> CGSize {
        return leftHandleImageView.image?.size ?? .zero
    }
    
    private func rightHandleImageSize() -> CGSize {
        return rightHandleImageView.image?.size ?? .zero
    }
    
    private func roundToNearestPixel(_ value: CGFloat) -> CGFloat {
        let scale = window?.contentScaleFactor ?? UIScreen.main.scale
        return (scale > 0.0) ? (round(value * scale) / scale) : 0.0
    }
}

private func imageNamed(_ name: String) -> UIImage? {
    return UIImage(named: name, in: Bundle(for: RangeSlider.self), compatibleWith: nil)
}

private func trackImage() -> UIImage? {
    let insets = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 4.0)
    return imageNamed("RangeSliderTrack")?.resizableImage(withCapInsets: insets)
}

private func fillImage() -> UIImage? {
    let insets = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 4.0)
    return imageNamed("RangeSliderFill")?.resizableImage(withCapInsets: insets)
}

private func leftHandleImage() -> UIImage? {
    return imageNamed("RangeSliderLeftHandle")
}

private func rightHandleImage() -> UIImage? {
    return imageNamed("RangeSliderRightHandle")
}
