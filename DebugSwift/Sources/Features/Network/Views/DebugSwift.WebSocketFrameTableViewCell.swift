//
//  WebSocketFrameTableViewCell.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class WebSocketFrameTableViewCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let directionIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 3
        return view
    }()
    
    private let directionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .lightGray
        return label
    }()
    
    private let payloadSizeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()
    
    private let payloadPreviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let frameTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .systemYellow
        label.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(directionIndicatorView)
        containerView.addSubview(directionLabel)
        containerView.addSubview(timestampLabel)
        containerView.addSubview(payloadSizeLabel)
        containerView.addSubview(frameTypeLabel)
        containerView.addSubview(payloadPreviewLabel)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Direction indicator
            directionIndicatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            directionIndicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            directionIndicatorView.widthAnchor.constraint(equalToConstant: 6),
            directionIndicatorView.heightAnchor.constraint(equalToConstant: 20),
            
            // Direction label
            directionLabel.leadingAnchor.constraint(equalTo: directionIndicatorView.trailingAnchor, constant: 8),
            directionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            
            // Timestamp label
            timestampLabel.leadingAnchor.constraint(equalTo: directionLabel.trailingAnchor, constant: 12),
            timestampLabel.centerYAnchor.constraint(equalTo: directionLabel.centerYAnchor),
            
            // Payload size label
            payloadSizeLabel.trailingAnchor.constraint(equalTo: frameTypeLabel.leadingAnchor, constant: -8),
            payloadSizeLabel.centerYAnchor.constraint(equalTo: directionLabel.centerYAnchor),
            
            // Frame type label
            frameTypeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            frameTypeLabel.centerYAnchor.constraint(equalTo: directionLabel.centerYAnchor),
            frameTypeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            frameTypeLabel.heightAnchor.constraint(equalToConstant: 16),
            
            // Payload preview label
            payloadPreviewLabel.leadingAnchor.constraint(equalTo: directionLabel.leadingAnchor),
            payloadPreviewLabel.topAnchor.constraint(equalTo: directionLabel.bottomAnchor, constant: 4),
            payloadPreviewLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            payloadPreviewLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            // Ensure timestamp doesn't overlap with payload size
            timestampLabel.trailingAnchor.constraint(lessThanOrEqualTo: payloadSizeLabel.leadingAnchor, constant: -8)
        ])
    }
    
    func configure(with frame: WebSocketFrame) {
        // Direction
        switch frame.direction {
        case .sent:
            directionLabel.text = "▲ SENT"
            directionIndicatorView.backgroundColor = .systemOrange
            containerView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        case .received:
            directionLabel.text = "▼ RECV"
            directionIndicatorView.backgroundColor = .systemBlue
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        }
        
        // Timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        timestampLabel.text = formatter.string(from: frame.timestamp)
        
        // Payload size
        payloadSizeLabel.text = "\(frame.payloadSize) bytes"
        
        // Frame type - use effective type and detect JSON
        let displayType = frameTypeString(for: frame)
        frameTypeLabel.text = displayType
        
        // Style frame type label based on content
        if frame.isJSON {
            frameTypeLabel.backgroundColor = .systemGreen.withAlphaComponent(0.2)
            frameTypeLabel.textColor = .systemGreen
        } else if frame.effectiveType == .binary {
            frameTypeLabel.backgroundColor = .systemYellow.withAlphaComponent(0.2)
            frameTypeLabel.textColor = .systemYellow
        } else {
            frameTypeLabel.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            frameTypeLabel.textColor = .systemBlue
        }
        
        // Payload preview - prioritize JSON formatting
        if frame.isJSON {
            payloadPreviewLabel.text = frame.prettyPrintedJSON ?? frame.payloadString ?? frame.payloadPreview
        } else {
            payloadPreviewLabel.text = frame.payloadString ?? frame.payloadPreview
        }
        
        // Adjust text color and type label based on content
        if frame.effectiveType == .binary {
            payloadPreviewLabel.textColor = .systemGray
        } else if frame.isJSON {
            payloadPreviewLabel.textColor = .systemGreen
        } else {
            payloadPreviewLabel.textColor = .white
        }
    }
    
    private func frameTypeString(for frame: WebSocketFrame) -> String {
        // Check for JSON first
        if frame.isJSON {
            return "JSON"
        }
        
        // Use effective type for display
        switch frame.effectiveType {
        case .text:
            return "TEXT"
        case .binary:
            return "BIN"
        case .ping:
            return "PING"
        case .pong:
            return "PONG"
        case .close:
            return "CLOSE"
        case .continuation:
            return "CONT"
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        directionLabel.text = nil
        timestampLabel.text = nil
        payloadSizeLabel.text = nil
        frameTypeLabel.text = nil
        frameTypeLabel.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        frameTypeLabel.textColor = .systemYellow
        payloadPreviewLabel.text = nil
        payloadPreviewLabel.textColor = .white
        containerView.backgroundColor = .darkGray.withAlphaComponent(0.3)
    }
} 