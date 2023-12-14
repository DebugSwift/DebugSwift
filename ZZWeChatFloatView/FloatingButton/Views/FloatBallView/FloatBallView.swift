//
//  FloatBallView.swift
//  ZZWeChatFloatView
//
//  Created by 周晓瑞 on 2018/6/14.
//  Copyright © 2018年 apple. All rights reserved.
//

import UIKit

protocol FloatViewDelegate: NSObjectProtocol {
    func floatViewBeginMove(floatView: FloatBallView, point: CGPoint)
    func floatViewMoved(floatView: FloatBallView, point: CGPoint)
    func floatViewCancelMove(floatView: FloatBallView)
}

class FloatBallView: UIView {

    weak var delegate: FloatViewDelegate?
    var ballDidSelect: (() -> Void)?

    fileprivate var beginPoint: CGPoint?

    var changeStatusInNextTransaction: Bool = true

    lazy var label: UILabel = buildLabel()

    var show: Bool = false {
        didSet {
            guard oldValue != show else { return }
            if show {
                DSFloatChat.window?.addSubview(self)
                self.alpha = .zero
                UIView.animate(withDuration: DSFloatChat.animationDuration) {
                    self.alpha = 1.0
                }
            } else {
                self.alpha = 1.0
                UIView.animate(withDuration: DSFloatChat.animationDuration, animations: {
                    self.alpha = .zero
                }) { (_) in
                     self.removeFromSuperview()
                }
            }
        }
    }

    var isShowing: Bool {
        DSFloatChat.window?.contains(self) == true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
        addGesture()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width * 0.5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func increment() {
        if var value = Int(label.text ?? "0") {
            value += 1
            label.text = .init(value)
        }

        startAnimation()
    }

    func reset() {
        label.text = "0"
    }
}

fileprivate extension FloatBallView {
    func addGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        tap.delaysTouchesBegan = true
        addGestureRecognizer(tap)
    }

    func setUp() {
        backgroundColor = .black
        layer.masksToBounds = true
        alpha = 0.0
        label.text = .init(0)
    }

    func buildLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 8)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        return label
    }

    func startAnimation() {
        // Create a label with the rocket emoji
        let label = UILabel()
        label.text = "🚀"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false

        // Add the label to the view
        superview?.addSubview(label)

        // Create constraints to center the label initially
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        let animator = UIViewPropertyAnimator(
            duration: 2,
            dampingRatio: 0.7
        ) {
            label.transform = CGAffineTransform(translationX: 0, y: -40) // Adjust the value as needed
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

fileprivate extension FloatBallView {
    @objc func tapGesture() {
       guard let ballDidSelect = ballDidSelect else {
           return
        }
         ballDidSelect()
    }
}

// MARK: - Gesture move

extension FloatBallView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        beginPoint = touches.first?.location(in: self)
        if let beginPoint = beginPoint {
            delegate?.floatViewBeginMove(floatView: self, point: beginPoint)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentPoint = touches.first?.location(in: self)

        guard let currentP = currentPoint, let beginP = beginPoint else {
            return
        }

        delegate?.floatViewMoved(floatView: self, point: currentP)

        let offsetX = currentP.x - beginP.x
        let offsetY = currentP.y - beginP.y
        center = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let superview = superview else { return }

        delegate?.floatViewCancelMove(floatView: self)

        let  marginLeft = frame.origin.x
        let  marginRight = superview.frame.width - frame.minX - frame.width
        let  marginTop = frame.minY
        let  marginBottom = superview.frame.height - self.frame.minY - frame.height

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
            destinationFrame = .init(x: tempX, y: DSFloatChat.padding + DSFloatChat.topSafeAreaPadding, width: DSFloatChat.ballRect.width, height: DSFloatChat.ballRect.height)
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
            destinationFrame = CGRect(x: tempX, y: superview.frame.height - frame.height-DSFloatChat.padding-DSFloatChat.bottomSafeAreaPadding, width: DSFloatChat.ballRect.width, height: DSFloatChat.ballRect.height)
        } else {
            destinationFrame = CGRect(x: marginLeft < marginRight ? DSFloatChat.padding : superview.frame.width - frame.width-DSFloatChat.padding, y: frame.minY, width: DSFloatChat.ballRect.width, height: DSFloatChat.ballRect.height)
        }

        UIView.animate(withDuration: DSFloatChat.animationDuration, animations: {
            self.frame = destinationFrame
        }) { (_) in

        }
    }
}
