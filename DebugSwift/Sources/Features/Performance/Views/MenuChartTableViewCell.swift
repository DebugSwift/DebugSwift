//
//  MenuChartTableViewCell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class MenuChartTableViewCell: UITableViewCell {
    let chartView: ChartView = {
        let chartView = ChartView()
        chartView.graphHeight = 220.0
        chartView.topPadding = 30
        chartView.filled = true
        chartView.layer.cornerRadius = 8
        chartView.layer.masksToBounds = true
        return chartView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.systemGray4.cgColor
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        selectionStyle = .none
        contentView.backgroundColor = UIColor.black
        backgroundColor = UIColor.black
        
        // Add container view
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add chart view to container
        containerView.addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Chart view constraints
            chartView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            chartView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            chartView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            chartView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    // Add subtle animation when the cell appears
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut) {
                self.transform = .identity
            }
        }
    }
}
