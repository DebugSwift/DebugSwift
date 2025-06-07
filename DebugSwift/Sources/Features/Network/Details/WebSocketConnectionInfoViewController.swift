//
//  WebSocketConnectionInfoViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class WebSocketConnectionInfoViewController: BaseController {
    
    private let connection: WebSocketConnection
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init(connection: WebSocketConnection) {
        self.connection = connection
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
        addNavigationButtons()
    }
    
    private func setupUI() {
        title = "Connection Info"
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupContent() {
        let infoSections = createInfoSections()
        
        var previousAnchor = contentView.topAnchor
        let sectionSpacing: CGFloat = 24
        
        for section in infoSections {
            contentView.addSubview(section)
            NSLayoutConstraint.activate([
                section.topAnchor.constraint(equalTo: previousAnchor, constant: sectionSpacing),
                section.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                section.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            previousAnchor = section.bottomAnchor
        }
        
        // Bottom spacing
        if let lastSection = infoSections.last {
            lastSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24).isActive = true
        }
    }
    
    private func createInfoSections() -> [UIView] {
        var sections: [UIView] = []
        
        // Basic Info Section
        let basicInfoSection = createSection(
            title: "Basic Information",
            items: [
                ("URL", connection.url.absoluteString),
                ("Channel Name", connection.channelName ?? "N/A"),
                ("Connection ID", connection.id),
                ("Status", connection.status.displayString)
            ]
        )
        sections.append(basicInfoSection)
        
        // Timestamps Section
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        let timestampsSection = createSection(
            title: "Timestamps",
            items: [
                ("Created At", formatter.string(from: connection.createdAt)),
                ("Last Activity", formatter.string(from: connection.lastActivityAt))
            ]
        )
        sections.append(timestampsSection)
        
        // Statistics Section
        let sentFrames = connection.frames.filter { $0.direction == .sent }.count
        let receivedFrames = connection.frames.filter { $0.direction == .received }.count
        let totalBytes = connection.frames.reduce(0) { $0 + $1.payloadSize }
        
        let statisticsSection = createSection(
            title: "Statistics",
            items: [
                ("Total Frames", "\(connection.frames.count)"),
                ("Sent Frames", "\(sentFrames)"),
                ("Received Frames", "\(receivedFrames)"),
                ("Unread Frames", "\(connection.unreadFrameCount)"),
                ("Total Bytes", formatBytes(totalBytes))
            ]
        )
        sections.append(statisticsSection)
        
        // Frame Types Section
        let frameTypeCounts = getFrameTypeCounts()
        if !frameTypeCounts.isEmpty {
                    let frameTypesSection = createSection(
            title: "Frame Types",
            items: frameTypeCounts.map { ("\(frameTypeDisplayName($0.key))", "\($0.value)") }
        )
            sections.append(frameTypesSection)
        }
        
        return sections
    }
    
    private func createSection(title: String, items: [(String, String)]) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .darkGray.withAlphaComponent(0.3)
        containerView.layer.cornerRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.text = title
        
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        var previousAnchor = titleLabel.bottomAnchor
        let itemSpacing: CGFloat = 12
        
        for (key, value) in items {
            let itemView = createInfoItem(key: key, value: value)
            containerView.addSubview(itemView)
            
            NSLayoutConstraint.activate([
                itemView.topAnchor.constraint(equalTo: previousAnchor, constant: itemSpacing),
                itemView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                itemView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            ])
            
            previousAnchor = itemView.bottomAnchor
        }
        
        // Bottom constraint
        if let lastItem = items.last {
            previousAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16).isActive = true
        }
        
        return containerView
    }
    
    private func createInfoItem(key: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let keyLabel = UILabel()
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        keyLabel.textColor = .lightGray
        keyLabel.text = key + ":"
        keyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        valueLabel.textColor = .white
        valueLabel.text = value
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right
        
        containerView.addSubview(keyLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            keyLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            keyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            keyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func getFrameTypeCounts() -> [WebSocketFrameType: Int] {
        var counts: [WebSocketFrameType: Int] = [:]
        
        for frame in connection.frames {
            counts[frame.type, default: 0] += 1
        }
        
        return counts
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func frameTypeDisplayName(_ type: WebSocketFrameType) -> String {
        switch type {
        case .text: return "Text"
        case .binary: return "Binary"
        case .ping: return "Ping"
        case .pong: return "Pong"
        case .close: return "Close"
        case .continuation: return "Continuation"
        }
    }
    
    private func addNavigationButtons() {
        // Close button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )
        
        // Copy URL button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(copyURL)
        )
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func copyURL() {
        UIPasteboard.general.string = connection.url.absoluteString
        
        showAlert(
            with: "URL copied to clipboard",
            title: "Copied!"
        )
    }
} 