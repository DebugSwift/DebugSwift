//
//  SparklineMetricCell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import UIKit

final class SparklineMetricCell: UITableViewCell {
    static let identifier = "SparklineMetricCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private let sparklineView = SparklineView()

    private let peakMinLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .gray
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none

        let topRow = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        topRow.axis = .horizontal
        topRow.alignment = .firstBaseline

        let stack = UIStackView(arrangedSubviews: [topRow, sparklineView, peakMinLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            sparklineView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func configure(
        title: String,
        value: String,
        color: UIColor,
        measurements: [CGFloat],
        peakText: String
    ) {
        titleLabel.text = title
        valueLabel.text = value
        valueLabel.textColor = color
        sparklineView.color = color
        sparklineView.values = measurements
        peakMinLabel.text = peakText
    }
}

// MARK: - SparklineView

private final class SparklineView: UIView {
    var values: [CGFloat] = [] { didSet { setNeedsDisplay() } }
    var color: UIColor = .systemGreen { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), values.count >= 2 else {
            drawPlaceholder(in: rect)
            return
        }

        let maxVal = values.max() ?? 1
        guard maxVal > 0 else {
            drawPlaceholder(in: rect)
            return
        }

        let step = rect.width / CGFloat(values.count - 1)

        let linePath = UIBezierPath()
        for (i, val) in values.enumerated() {
            let x = CGFloat(i) * step
            let y = rect.height * (1 - val / maxVal)
            if i == 0 { linePath.move(to: CGPoint(x: x, y: y)) }
            else { linePath.addLine(to: CGPoint(x: x, y: y)) }
        }

        // Fill
        let fillPath = linePath.copy() as! UIBezierPath
        fillPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        fillPath.addLine(to: CGPoint(x: 0, y: rect.height))
        fillPath.close()

        ctx.saveGState()
        fillPath.addClip()
        let colors = [color.withAlphaComponent(0.3).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: rect.height), options: [])
        }
        ctx.restoreGState()

        // Line
        color.setStroke()
        linePath.lineWidth = 1.5
        linePath.lineJoinStyle = .round
        linePath.stroke()
    }

    private func drawPlaceholder(in rect: CGRect) {
        UIColor.systemGray5.withAlphaComponent(0.3).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
    }
}
