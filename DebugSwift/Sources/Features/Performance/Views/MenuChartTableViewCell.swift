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
        chartView.graphHeight = 200.0
        chartView.topPadding = 20
        return chartView
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
        // Add and configure the chart view
        contentView.addSubview(chartView)
        contentView.backgroundColor = Theme.shared.setupBackgroundColor()
        backgroundColor = Theme.shared.setupBackgroundColor()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
