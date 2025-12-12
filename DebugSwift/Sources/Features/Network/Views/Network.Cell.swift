//
//  Network.Cell.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class NetworkTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    private let methodLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .right
        return label
    }()

    private let statusCodeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        return label
    }()

    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        label.textColor = .darkGray
        return label
    }()
    
    // New enhanced components
    private let performanceIndicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        return view
    }()
    
    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = .systemOrange
        return label
    }()
    
    private let contentTypeIndicator: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9, weight: .medium)
        label.textColor = .systemPurple
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
        label.textAlignment = .center
        return label
    }()
    
    private let errorIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        view.isHidden = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(_ model: HttpModel) {
        // Method and basic info
        methodLabel.text = "[\(model.method ?? "GET")]"
        numberLabel.text = model.id
        statusCodeLabel.text = model.statusCode
        descriptionLabel.text = formatURL(model.url?.absoluteString)
        timestampLabel.text = formatTimestamp(model.startTime)
        
        // Performance indicators
        setupPerformanceIndicators(model)
        setupStatusColors(model)
        setupContentTypeIndicator(model)
        setupSizeAndDuration(model)
        
        // Error state
        errorIndicator.isHidden = model.isSuccess
    }
    
    private func formatURL(_ urlString: String?) -> String {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return "Invalid URL"
        }
        
        // Show domain + path in a more readable format
        let domain = url.host ?? "unknown"
        let path = url.path.isEmpty ? "/" : url.path
        
        if let query = url.query, !query.isEmpty {
            return "\(domain)\(path)?\(query)"
        }
        
        return "\(domain)\(path)"
    }
    
    private func formatTimestamp(_ timestamp: String?) -> String {
        guard let timestamp = timestamp else { return "Unknown" }
        
        // Parse the timestamp and format it as HH:mm:ss - MM/dd
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss - dd/MM/yyyy"
        inputFormatter.locale = Locale(identifier: "pt_BR")
        
        if let date = inputFormatter.date(from: timestamp) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "HH:mm:ss - MM/dd"
            return outputFormatter.string(from: date)
        }
        
        // Fallback: try to extract time portion if it's a different format
        if let range = timestamp.range(of: " ") {
            let timeString = String(timestamp[range.upperBound...])
            return timeString.components(separatedBy: ".").first ?? timeString
        }
        
        return timestamp
    }
    
    private func setupPerformanceIndicators(_ model: HttpModel) {
        // Performance color based on response time
        let performanceColor = getPerformanceColor(duration: model.totalDuration)
        performanceIndicatorView.backgroundColor = performanceColor
    }
    
    private func setupStatusColors(_ model: HttpModel) {
        let statusColor = getStatusColor(model)
        numberLabel.textColor = statusColor
        statusCodeLabel.textColor = statusColor
        timestampLabel.textColor = statusColor
    }
    
    private func setupContentTypeIndicator(_ model: HttpModel) {
        guard let mimeType = model.mineType else {
            contentTypeIndicator.isHidden = true
            return
        }
        
        contentTypeIndicator.isHidden = false
        contentTypeIndicator.text = getContentTypeDisplay(mimeType)
    }
    
    private func setupSizeAndDuration(_ model: HttpModel) {
        sizeLabel.text = model.size ?? "0B"
        
        if let duration = model.totalDuration {
            // Remove " (s)" suffix and format nicely
            let cleanDuration = duration.replacingOccurrences(of: " (s)", with: "")
            if let durationValue = Double(cleanDuration) {
                if durationValue < 1.0 {
                    durationLabel.text = String(format: "%.0fms", durationValue * 1000)
                } else {
                    durationLabel.text = String(format: "%.2fs", durationValue)
                }
            } else {
                durationLabel.text = duration
            }
        } else {
            durationLabel.text = "0ms"
        }
    }
    
    private func getPerformanceColor(duration: String?) -> UIColor {
        guard let duration = duration,
              let durationValue = Double(duration.replacingOccurrences(of: " (s)", with: "")) else {
            return .gray
        }
        
        // Performance color coding
        if durationValue < 0.1 { return .systemGreen }      // < 100ms - Excellent
        if durationValue < 0.5 { return .systemYellow }     // < 500ms - Good
        if durationValue < 1.0 { return .systemOrange }     // < 1s - Fair
        return .systemRed                                    // > 1s - Poor
    }
    
    private func getStatusColor(_ model: HttpModel) -> UIColor {
        guard let statusCode = model.statusCode, let code = Int(statusCode) else {
            return .systemRed
        }
        
        switch code {
        case 200..<300: return .systemGreen    // Success
        case 300..<400: return .systemBlue     // Redirection
        case 400..<500: return .systemOrange   // Client Error
        case 500..<600: return .systemRed      // Server Error
        default: return .systemGray            // Other
        }
    }
    
    private func getContentTypeDisplay(_ mimeType: String) -> String {
        let type = mimeType.lowercased()
        
        if type.contains("json") { return "JSON" }
        if type.contains("xml") { return "XML" }
        if type.contains("html") { return "HTML" }
        if type.contains("image") { return "IMG" }
        if type.contains("video") { return "VID" }
        if type.contains("audio") { return "AUD" }
        if type.contains("pdf") { return "PDF" }
        if type.contains("text") { return "TXT" }
        
        return "DATA"
    }

    private func setupUI() {
        setupViews()
        setupConstraints()
    }

    func setupViews() {
        [methodLabel, numberLabel, statusCodeLabel, descriptionLabel, 
         timestampLabel, performanceIndicatorView, sizeLabel, durationLabel,
         contentTypeIndicator, errorIndicator].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.backgroundColor = UIColor.black
        backgroundColor = UIColor.black
        selectionStyle = .none
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Performance indicator (left edge)
            performanceIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            performanceIndicatorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            performanceIndicatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            performanceIndicatorView.widthAnchor.constraint(equalToConstant: 4),
            
            // Method label
            methodLabel.leadingAnchor.constraint(equalTo: performanceIndicatorView.trailingAnchor, constant: 8),
            methodLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            methodLabel.widthAnchor.constraint(equalToConstant: 60),
            
            // Number label
            numberLabel.leadingAnchor.constraint(equalTo: methodLabel.trailingAnchor, constant: 4),
            numberLabel.centerYAnchor.constraint(equalTo: methodLabel.centerYAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 30),
            
            // Status code (right side)
            statusCodeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusCodeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            statusCodeLabel.widthAnchor.constraint(equalToConstant: 50),
            
            // Error indicator
            errorIndicator.trailingAnchor.constraint(equalTo: statusCodeLabel.leadingAnchor, constant: -4),
            errorIndicator.centerYAnchor.constraint(equalTo: statusCodeLabel.centerYAnchor),
            errorIndicator.widthAnchor.constraint(equalToConstant: 8),
            errorIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // URL description
            descriptionLabel.leadingAnchor.constraint(equalTo: methodLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: errorIndicator.leadingAnchor, constant: -8),
            descriptionLabel.topAnchor.constraint(equalTo: methodLabel.bottomAnchor, constant: 4),
            
            // Content type indicator
            contentTypeIndicator.leadingAnchor.constraint(equalTo: methodLabel.leadingAnchor),
            contentTypeIndicator.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            contentTypeIndicator.widthAnchor.constraint(equalToConstant: 45),
            contentTypeIndicator.heightAnchor.constraint(equalToConstant: 16),
            
            // Size label
            sizeLabel.leadingAnchor.constraint(equalTo: contentTypeIndicator.trailingAnchor, constant: 8),
            sizeLabel.centerYAnchor.constraint(equalTo: contentTypeIndicator.centerYAnchor),
            
            // Duration label
            durationLabel.leadingAnchor.constraint(equalTo: sizeLabel.trailingAnchor, constant: 12),
            durationLabel.centerYAnchor.constraint(equalTo: contentTypeIndicator.centerYAnchor),
            
            // Timestamp (bottom right)
            timestampLabel.trailingAnchor.constraint(equalTo: statusCodeLabel.trailingAnchor),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Ensure content type indicator also respects bottom boundary
            contentTypeIndicator.bottomAnchor.constraint(lessThanOrEqualTo: timestampLabel.topAnchor, constant: -4),
            
            // Cell height - allow dynamic expansion based on content
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])
    }
}
