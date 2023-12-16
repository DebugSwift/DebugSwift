//
//  SliderTableViewCell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

protocol SliderTableViewCellDelegate: AnyObject {
    func sliderCell(_ sliderCell: SliderTableViewCell, didSelectValue value: CGFloat)
    func sliderCellDidStartEditingValue(_ sliderCell: SliderTableViewCell)
    func sliderCellDidEndEditingValue(_ sliderCell: SliderTableViewCell)
}

class SliderTableViewCell: UITableViewCell {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    weak var delegate: SliderTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(slider)
        contentView.backgroundColor = .black

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            slider.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: valueLabel.trailingAnchor),
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])

        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderEditingDidBegin(_:)), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderEditingDidEnd(_:)), for: .touchUpInside)
    }

    func setValue(_ value: CGFloat) {
        slider.value = Float(value)
        updateValueLabel()
    }

    func setMinValue(_ minValue: CGFloat) {
        slider.minimumValue = Float(minValue)
    }

    func setMaxValue(_ maxValue: CGFloat) {
        if maxValue == 1 {
            slider.tag = SliderType.float.rawValue
        } else {
            slider.tag = SliderType.int.rawValue
        }
        slider.maximumValue = Float(maxValue)
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        updateValueLabel()
        delegate?.sliderCell(self, didSelectValue: CGFloat(sender.value))
    }

    @objc func sliderEditingDidBegin(_ sender: UISlider) {
        delegate?.sliderCellDidStartEditingValue(self)
    }

    @objc func sliderEditingDidEnd(_ sender: UISlider) {
        delegate?.sliderCellDidEndEditingValue(self)
    }

    private func updateValueLabel() {
        switch SliderType(rawValue: slider.tag) {
        case .float:
            valueLabel.text  = String(format: "%.1lf%%", slider.value)

        case .int:
            valueLabel.text = "\(Int(slider.value))"
        default:
            break
        }
    }
}

extension SliderTableViewCell {
    enum SliderType: Int {
        case float
        case int
    }
}
