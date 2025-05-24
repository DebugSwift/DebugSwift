//
//  FloatBallView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2018/6/14.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

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
            updateText()
            guard oldValue != show else { return }
            if show {
                WindowManager.window.addSubview(self)
                layer.position = .init(
                    x: 20,
                    y: UIScreen.main.bounds.height / 2 - 80
                )
                alpha = .zero
                UIView.animate(withDuration: DSFloatChat.animationDuration) {
                    self.alpha = 1.0
                }
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
            }
        }
    }

    var isShowing: Bool {
        WindowManager.window.contains(self) == true
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        addGesture()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        ballView.layer.cornerRadius = DSFloatChat.ballViewSize.width / 2
    }

    func animate(success: Bool) {
        guard isShowing else { return }

        label.text = .init(HttpDatasource.shared.httpModels.count)
        startAnimation(text: success ? "🚀" : "❌")

        if !success { ImpactFeedback.generate() }
    }

    func animateLeek(alloced: Bool) {
        guard isShowing else { return }

        startAnimation(text: alloced ? "⚠️" : "✳️")

        ImpactFeedback.generate(.init(style: .heavy))
    }

    func updateText() {
        label.text = .init(HttpDatasource.shared.httpModels.count)
    }

    func reset() {
        label.text = "0"
    }
}

extension FloatBallView {
    private func addGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        tap.delaysTouchesBegan = true
        addGestureRecognizer(tap)

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        addGestureRecognizer(longPressGestureRecognizer)
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

        let animator = UIViewPropertyAnimator(
            duration: 2,
            dampingRatio: 0.7
        ) {
            label.transform = CGAffineTransform(translationX: 0, y: -40)
            label.alpha = 0
        }

        animator.addCompletion { position in
            if position == .end {
                label.removeFromSuperview()
            }
        }

        animator.startAnimation()
    }
}

extension FloatBallView {
    @objc private func tapGesture() {
        ballDidSelect?()
    }

    @objc private func handleLongPress() {
        WindowManager.presentViewDebugger()
    }
}

// MARK: - Gesture move

extension FloatBallView {
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        beginPoint = touches.first?.location(in: self)
        if let beginPoint {
            delegate?.floatViewBeginMove(floatView: self, point: beginPoint)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        let currentPoint = touches.first?.location(in: self)

        guard let currentP = currentPoint, let beginP = beginPoint else {
            return
        }

        delegate?.floatViewMoved(floatView: self, point: currentP)

        let offsetX = currentP.x - beginP.x
        let offsetY = currentP.y - beginP.y
        center = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        guard let superview else { return }

        delegate?.floatViewCancelMove(floatView: self)

        let marginLeft = frame.origin.x
        let marginRight = superview.frame.width - frame.minX - frame.width
        let marginTop = frame.minY
        let marginBottom = superview.frame.height - frame.minY - frame.height

        var destinationFrame = frame

        var tempX: CGFloat = .zero

        if marginTop < 60 {
            if marginLeft < marginRight {
                if marginLeft < DSFloatChat.padding {
                    tempX = DSFloatChat.padding
                } else {
                    tempX = frame.minX
                }
            } else {
                if marginRight < DSFloatChat.padding {
                    tempX = superview.frame.width - frame.width - DSFloatChat.padding
                } else {
                    tempX = frame.minX
                }
            }
            destinationFrame = .init(
                x: tempX,
                y: DSFloatChat.padding + DSFloatChat.topSafeAreaPadding,
                width: DSFloatChat.ballRect.width,
                height: DSFloatChat.ballRect.height
            )
        } else if marginBottom < 60 {
            if marginLeft < marginRight {
                if marginLeft < DSFloatChat.padding {
                    tempX = DSFloatChat.padding
                } else {
                    tempX = frame.minX
                }
            } else {
                if marginRight < DSFloatChat.padding {
                    tempX = superview.frame.width - frame.width - DSFloatChat.padding
                } else {
                    tempX = frame.minX
                }
            }
            destinationFrame = CGRect(
                x: tempX,
                y: superview.frame.height - frame.height - DSFloatChat.padding
                    - DSFloatChat.bottomSafeAreaPadding,
                width: DSFloatChat.ballRect.width,
                height: DSFloatChat.ballRect.height
            )
        } else {
            destinationFrame = CGRect(
                x: marginLeft < marginRight
                    ? DSFloatChat.padding : superview.frame.width - frame.width - DSFloatChat.padding,
                y: frame.minY,
                width: DSFloatChat.ballRect.width,
                height: DSFloatChat.ballRect.height
            )
        }

        UIView.animate(
            withDuration: DSFloatChat.animationDuration,
            animations: {
                self.frame = destinationFrame
            }
        ) { _ in
        }
    }
}
