//
//  Performance.WidgetView.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

enum PerformanceSection: Int {
    case CPU
    case Memory
    case FPS
}

class PerformanceWidgetView: UIView {

    private let widgetMinimalOffset: CGFloat = 10
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private static let labelFontSize: CGFloat = 12

    let cpuValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: labelFontSize)
        label.textColor = .white
        return label
    }()

    let memoryValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: labelFontSize)
        label.textColor = .white
        return label
    }()

    let fpsValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: labelFontSize)
        label.textColor = .white
        return label
    }()

    weak var delegate: PerformanceWidgetViewDelegate?
    private var widgetWindow: UIWindow?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateValues(cpu: CGFloat, memory: CGFloat, fps: CGFloat) {
        cpuValueLabel.text = String(format: "CPU: %.1lf%%", cpu)
        memoryValueLabel.text = String(format: "Memory: %.1lf MB", memory)
        fpsValueLabel.text = String(format: "FPS: %.0lf", fps)
    }

    func toggle(with newValue: Bool) {
        if newValue {
            showWidgetWindow()
        }

        UIView.animate(withDuration: 0.35, animations: {
            self.alpha = newValue ? 1.0 : 0.0
        }) { (_) in
            self.isHidden = !newValue
            if !newValue {
                self.removeWidgetWindow()
            }
        }
    }

    private func showWidgetWindow() {
        widgetWindow = UIWindow(frame: UIScreen.main.bounds)
        widgetWindow?.rootViewController = UIViewController()
        widgetWindow?.rootViewController?.view.addSubview(self)
        widgetWindow?.isHidden = false
        setup()

        alpha = 0.0
        UIView.animate(withDuration: 0.35) { self.alpha = 1.0 }
        widgetWindow?.isUserInteractionEnabled = false
    }

    private func removeWidgetWindow() {
        widgetWindow?.isHidden = true
        widgetWindow = nil
    }

    private func setup() {
        guard let superview = widgetWindow?.rootViewController?.view else { return }
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -90),
            heightAnchor.constraint(equalToConstant: 30)
        ])

        backgroundColor = .black

        layer.borderWidth = 3.0 / UIScreen.main.scale
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = 15

        let stackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 12
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()

        stackView.addArrangedSubview(cpuValueLabel)
        stackView.addArrangedSubview(memoryValueLabel)
        stackView.addArrangedSubview(fpsValueLabel)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

protocol PerformanceWidgetViewDelegate: AnyObject {
    func performanceWidgetView(_ performanceWidgetView: PerformanceWidgetView, didTapOnSection section: PerformanceSection)
}
