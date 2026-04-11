//
//  FloatBallView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2018/6/14.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit
import SwiftUI

@MainActor
protocol FloatViewDelegate: NSObjectProtocol {
    func floatViewBeginMove(floatView: FloatBallView, point: CGPoint)
    func floatViewMoved(floatView: FloatBallView, point: CGPoint)
    func floatViewCancelMove(floatView: FloatBallView)
}

class FloatBallView: UIView {
    weak var delegate: FloatViewDelegate?
    var ballDidSelect: (() -> Void)?

    fileprivate var beginPoint: CGPoint?

    var changeStatusInNextTransaction = true

    lazy var label: UILabel = buildLabel()
    lazy var ballView: UIView = buildBallView()

    var show = false {
        didSet {
            guard oldValue != show else { return }
            if show {
                label.text = "0"
                WindowManager.window.addSubview(self)
                restoreSavedPosition()
                alpha = .zero
                UIView.animate(withDuration: DSFloatChat.animationDuration) {
                    self.alpha = 1.0
                }
                setupMeasurementStateObserver()
            } else {
                alpha = 1.0
                UIView.animate(
                    withDuration: DSFloatChat.animationDuration,
                    animations: {
                        self.alpha = .zero
                    }
                ) { _ in
                    self.removeFromSuperview()
                }
                removeMeasurementStateObserver()
            }
        }
    }

    var isShowing: Bool {
        WindowManager.window.contains(self) == true
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        addGesture()
        updateBallAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        ballView.layer.cornerRadius = DSFloatChat.ballViewSize.width / 2
    }
    
    private func setupMeasurementStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(measurementStateChanged),
            name: MeasurementWindowManager.measurementStateChangedNotification,
            object: nil
        )
    }
    
    private func removeMeasurementStateObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func measurementStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateBallAppearance()
        }
    }

    func animate(success: Bool) {
        guard isShowing else { return }
        
        // Debounce frequent animations
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performAnimation(_:)), object: nil)
        
        updateText()
        perform(#selector(performAnimation(_:)), with: success, afterDelay: 0.1)

        if !success { ImpactFeedback.generate() }
    }
    
    @objc private func performAnimation(_ success: NSNumber) {
        startAnimation(text: success.boolValue ? "🚀" : "❌")
    }
    
    func animateWebSocket(connected: Bool) {
        guard isShowing else { return }

        updateText()
        startAnimation(text: connected ? "⚡" : "🔗")
    }

    func animateLeek(alloced: Bool) {
        guard isShowing else { return }

        startAnimation(text: alloced ? "⚠️" : "✳️")

        ImpactFeedback.generate(.init(style: .heavy))
    }

    func updateText() {
        // Only update if showing to avoid unnecessary work
        guard isShowing else { return }
        
        let httpCount = HttpDatasource.shared.httpModels.count
        let webSocketCount = WebSocketDataSource.shared.getAllConnections().count
        let totalCount = httpCount + webSocketCount
        
        // Only update if the count has actually changed
        let newText = String(totalCount)
        if label.text != newText {
            label.text = newText
        }
    }

    func reset() {
        label.text = "0"
    }

    private func restoreSavedPosition() {
        layer.position = FloatBallPositionHelper.restoreSavedPosition(in: WindowManager.window)
    }
}

extension FloatBallView {
    private func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clickBall))
        addGestureRecognizer(tapGesture)
        
        // Add long press gesture for HyperionSwift toggle
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressBall))
        longPressGesture.minimumPressDuration = 0.8
        addGestureRecognizer(longPressGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ballPan))
        addGestureRecognizer(panGesture)
    }

    private func buildLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.font = .systemFont(ofSize: 8)
        label.text = .init(0)
        ballView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        return label
    }

    private func buildBallView() -> UIView {
        let padding: CGFloat = (DSFloatChat.ballRect.width - DSFloatChat.ballViewSize.width) / 2
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 0.6

        addSubview(view)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: DSFloatChat.ballViewSize.width),
            view.heightAnchor.constraint(equalToConstant: DSFloatChat.ballViewSize.height),
            view.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
        return view
    }

    private func startAnimation(text: String) {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        superview?.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        Task { @MainActor in
            let animator = UIViewPropertyAnimator(
                duration: 2,
                dampingRatio: 0.7
            ) {
                label.transform = CGAffineTransform(translationX: 0, y: -40)
                label.alpha = 0
            }
            animator.startAnimation()
            
            let position = await animator.addCompletion()
            if position == .end {
                label.removeFromSuperview()
            }
        }
    }
}

extension FloatBallView {
    @objc func clickBall() {
        WindowManager.presentDebugger()
        ballDidSelect?()
    }
    
    @objc func longPressBall(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        DispatchQueue.main.async {
            WindowManager.presentViewDebugger()
        }
    }
    
    private func updateBallAppearance() {
        // Update ball appearance based on measurement state
        if DebugSwift.Measurement.isActive {
            ballView.layer.borderWidth = 2
            ballView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            ballView.layer.borderWidth = 0.6
            ballView.layer.borderColor = UIColor.white.cgColor
        }
    }

    @objc func ballPan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            beginPoint = pan.location(in: self)
            delegate?.floatViewBeginMove(floatView: self, point: beginPoint!)
        case .changed:
            let currentPoint = pan.translation(in: self)
            let x = layer.position.x + currentPoint.x
            let y = layer.position.y + currentPoint.y
            layer.position = CGPoint(x: x, y: y)
            pan.setTranslation(.zero, in: self)
            delegate?.floatViewMoved(floatView: self, point: .init(x: x, y: y))
        case .ended, .cancelled:
            let velocityPoint = pan.velocity(in: self)
            let window = WindowManager.window

            delegate?.floatViewCancelMove(floatView: self)

            let targetPosition = FloatBallPositionHelper.finalizedDragPosition(
                from: layer.position,
                in: window
            )

            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: abs(velocityPoint.x / layer.position.x),
                options: [],
                animations: {
                    self.layer.position = targetPosition
                }
            )
        default:
            break
        }
    }
}
