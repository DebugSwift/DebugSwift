//
//  Performance.WidgetView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

enum PerformanceSection: Int {
    case cpu
    case memory
    case fps
    case leaks
    case heap
}

final class PerformanceWidgetView: TopLevelViewWrapper {
    private let widgetMinimalOffset: CGFloat = 10
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private static let labelFontSize: CGFloat = 12

    let cpuValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: labelFontSize)
        label.textColor = UIColor.white
        return label
    }()

    let memoryValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: labelFontSize)
        label.textColor = UIColor.white
        return label
    }()

    let fpsValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: labelFontSize)
        label.textColor = UIColor.white
        return label
    }()

    let leaksValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: labelFontSize)
        label.textColor = UIColor.white
        return label
    }()

    weak var delegate: PerformanceWidgetViewDelegate?

    func updateValues(cpu: CGFloat, memory: CGFloat, fps: CGFloat, leaks: CGFloat) {
        cpuValueLabel.text = String(format: "\("CPU"): %.1lf%%", cpu)
        memoryValueLabel.text = String(format: "\("Memory"): %.1lf MB", memory)
        fpsValueLabel.text = String(format: "\("FPS"): %.0lf", fps)
        leaksValueLabel.text = String(format: "\("Leaks"): %.0lf", leaks)
    }

    override func showWidgetWindow() {
        super.showWidgetWindow()
        setup()
    }

    private func setup() {
        guard
            let superview = WindowManager.window.rootViewController?.view
        else { return }

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -90),
            heightAnchor.constraint(equalToConstant: 30)
        ])

        backgroundColor = UIColor.black

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
        if !DebugSwift.App.shared.disableMethods.contains(.leaksDetector) {
            stackView.addArrangedSubview(leaksValueLabel)
        }

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.alpha = 0.7
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@MainActor
protocol PerformanceWidgetViewDelegate: AnyObject {
    func performanceWidgetView(
        _ performanceWidgetView: PerformanceWidgetView, didTapOnSection section: PerformanceSection
    )
}
