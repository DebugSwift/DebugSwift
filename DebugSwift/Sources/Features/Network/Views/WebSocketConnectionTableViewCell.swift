//
//  WebSocketConnectionTableViewCell.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class WebSocketConnectionTableViewCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let statusIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        return view
    }()
    
    private let urlLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let channelNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 1
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private let frameCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        return label
    }()
    
    private let unreadBadgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()
    
    private let lastActivityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = .right
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
        
        containerView.addSubview(statusIndicatorView)
        containerView.addSubview(urlLabel)
        containerView.addSubview(channelNameLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(frameCountLabel)
        containerView.addSubview(unreadBadgeLabel)
        containerView.addSubview(lastActivityLabel)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Status indicator
            statusIndicatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusIndicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusIndicatorView.widthAnchor.constraint(equalToConstant: 12),
            statusIndicatorView.heightAnchor.constraint(equalToConstant: 12),
            
            // URL label
            urlLabel.leadingAnchor.constraint(equalTo: statusIndicatorView.trailingAnchor, constant: 8),
            urlLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            urlLabel.trailingAnchor.constraint(equalTo: unreadBadgeLabel.leadingAnchor, constant: -8),
            
            // Channel name label
            channelNameLabel.leadingAnchor.constraint(equalTo: urlLabel.leadingAnchor),
            channelNameLabel.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 2),
            channelNameLabel.trailingAnchor.constraint(equalTo: urlLabel.trailingAnchor),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: urlLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: channelNameLabel.bottomAnchor, constant: 4),
            
            // Frame count label
            frameCountLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 16),
            frameCountLabel.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            
            // Unread badge
            unreadBadgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            unreadBadgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            unreadBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            unreadBadgeLabel.heightAnchor.constraint(equalToConstant: 16),
            
            // Last activity label
            lastActivityLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            lastActivityLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            lastActivityLabel.leadingAnchor.constraint(greaterThanOrEqualTo: frameCountLabel.trailingAnchor, constant: 8),
            
            // Ensure status label doesn't conflict with last activity
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: lastActivityLabel.topAnchor, constant: -4)
        ])
    }
    
    func configure(with connection: WebSocketConnection) {
        // URL
        urlLabel.text = connection.url.absoluteString
        
        // Channel name
        if let channelName = connection.channelName {
            channelNameLabel.text = "Channel: \(channelName)"
            channelNameLabel.isHidden = false
        } else {
            channelNameLabel.isHidden = true
        }
        
        // Status
        statusLabel.text = connection.status.displayString
        statusLabel.textColor = connection.status.color
        statusIndicatorView.backgroundColor = connection.status.color
        
        // Frame count
        frameCountLabel.text = "\(connection.frames.count) frames"
        
        // Unread badge
        if connection.unreadFrameCount > 0 {
            unreadBadgeLabel.text = "\(connection.unreadFrameCount)"
            unreadBadgeLabel.isHidden = false
        } else {
            unreadBadgeLabel.isHidden = true
        }
        
        // Last activity
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        lastActivityLabel.text = formatter.localizedString(for: connection.lastActivityAt, relativeTo: Date())
        
        // Visual feedback for active/inactive connections
        containerView.alpha = connection.isActive ? 1.0 : 0.7
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        urlLabel.text = nil
        channelNameLabel.text = nil
        statusLabel.text = nil
        frameCountLabel.text = nil
        unreadBadgeLabel.text = nil
        lastActivityLabel.text = nil
        unreadBadgeLabel.isHidden = true
        channelNameLabel.isHidden = false
        containerView.alpha = 1.0
    }
} 