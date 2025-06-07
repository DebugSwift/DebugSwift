//
//  WebSocketFrameDetailViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class WebSocketFrameDetailViewController: BaseController {
    
    private let frame: WebSocketFrame
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
    
    private let headerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let payloadContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var payloadTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        textView.layer.cornerRadius = 4
        return textView
    }()
    
    private lazy var hexTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .black.withAlphaComponent(0.3)
        textView.textColor = .systemGreen
        textView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        textView.layer.cornerRadius = 4
        textView.isHidden = true
        return textView
    }()
    
    private lazy var viewModeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Pretty", "Raw", "Hex"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.backgroundColor = .darkGray
        control.selectedSegmentTintColor = .systemBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(viewModeChanged), for: .valueChanged)
        return control
    }()
    
    init(frame: WebSocketFrame, connection: WebSocketConnection) {
        self.frame = frame
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
        title = "Frame Detail"
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerContainer)
        contentView.addSubview(viewModeSegmentedControl)
        contentView.addSubview(payloadContainer)
        payloadContainer.addSubview(payloadTextView)
        payloadContainer.addSubview(hexTextView)
        
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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header container
            headerContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // View mode control
            viewModeSegmentedControl.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 16),
            viewModeSegmentedControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Payload container
            payloadContainer.topAnchor.constraint(equalTo: viewModeSegmentedControl.bottomAnchor, constant: 16),
            payloadContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            payloadContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            payloadContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            payloadContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            // Payload text view
            payloadTextView.topAnchor.constraint(equalTo: payloadContainer.topAnchor, constant: 8),
            payloadTextView.leadingAnchor.constraint(equalTo: payloadContainer.leadingAnchor, constant: 8),
            payloadTextView.trailingAnchor.constraint(equalTo: payloadContainer.trailingAnchor, constant: -8),
            payloadTextView.bottomAnchor.constraint(equalTo: payloadContainer.bottomAnchor, constant: -8),
            
            // Hex text view
            hexTextView.topAnchor.constraint(equalTo: payloadContainer.topAnchor, constant: 8),
            hexTextView.leadingAnchor.constraint(equalTo: payloadContainer.leadingAnchor, constant: 8),
            hexTextView.trailingAnchor.constraint(equalTo: payloadContainer.trailingAnchor, constant: -8),
            hexTextView.bottomAnchor.constraint(equalTo: payloadContainer.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupContent() {
        setupHeader()
        setupPayload()
        
        // Hide hex view for binary frames initially, unless user specifically requests it
        if frame.type == .binary {
            viewModeSegmentedControl.selectedSegmentIndex = 2
            viewModeChanged()
        }
    }
    
    private func setupHeader() {
        // Create header labels
        let infoLabels = createHeaderLabels()
        
        var previousAnchor = headerContainer.topAnchor
        let margin: CGFloat = 8
        
        for label in infoLabels {
            headerContainer.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: previousAnchor, constant: margin),
                label.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -12)
            ])
            previousAnchor = label.bottomAnchor
        }
        
        // Bottom constraint for the last label
        if let lastLabel = infoLabels.last {
            lastLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -margin).isActive = true
        }
    }
    
    private func createHeaderLabels() -> [UILabel] {
        var labels: [UILabel] = []
        
        // Direction
        let directionLabel = createInfoLabel(
            title: "Direction:",
            value: frame.direction == .sent ? "▲ Sent" : "▼ Received",
            valueColor: frame.direction == .sent ? .systemOrange : .systemBlue
        )
        labels.append(directionLabel)
        
        // Timestamp
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        formatter.locale = Locale.current
        let timestampLabel = createInfoLabel(
            title: "Timestamp:",
            value: formatter.string(from: frame.timestamp)
        )
        labels.append(timestampLabel)
        
        // Frame type
        let typeLabel = createInfoLabel(
            title: "Type:",
            value: frameTypeString(for: frame.type),
            valueColor: .systemYellow
        )
        labels.append(typeLabel)
        
        // Payload size
        let sizeLabel = createInfoLabel(
            title: "Size:",
            value: "\(frame.payloadSize) bytes"
        )
        labels.append(sizeLabel)
        
        return labels
    }
    
    private func createInfoLabel(title: String, value: String, valueColor: UIColor = .white) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        let attributedString = NSMutableAttributedString()
        
        // Title part
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.lightGray
        ]
        attributedString.append(NSAttributedString(string: title + " ", attributes: titleAttributes))
        
        // Value part
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: valueColor
        ]
        attributedString.append(NSAttributedString(string: value, attributes: valueAttributes))
        
        label.attributedText = attributedString
        return label
    }
    
    private func setupPayload() {
        updatePayloadDisplay()
    }
    
    @objc private func viewModeChanged() {
        updatePayloadDisplay()
    }
    
    private func updatePayloadDisplay() {
        payloadTextView.isHidden = true
        hexTextView.isHidden = true
        
        switch viewModeSegmentedControl.selectedSegmentIndex {
        case 0: // Pretty
            payloadTextView.isHidden = false
            if let prettyJSON = frame.prettyPrintedJSON {
                payloadTextView.text = prettyJSON
            } else if let payloadString = frame.payloadString {
                payloadTextView.text = payloadString
            } else {
                payloadTextView.text = "Binary data - switch to Hex view to inspect"
            }
            
        case 1: // Raw
            payloadTextView.isHidden = false
            if let payloadString = frame.payloadString {
                payloadTextView.text = payloadString
            } else {
                payloadTextView.text = "Binary data - switch to Hex view to inspect"
            }
            
        case 2: // Hex
            hexTextView.isHidden = false
            hexTextView.text = formatHexDump(frame.hexDump)
            
        default:
            break
        }
    }
    
    private func formatHexDump(_ hexString: String) -> String {
        let hexBytes = hexString.components(separatedBy: " ")
        var result = ""
        
        for (index, byte) in hexBytes.enumerated() {
            if index > 0 && index % 16 == 0 {
                result += "\n"
            } else if index > 0 && index % 8 == 0 {
                result += "  "
            } else if index > 0 {
                result += " "
            }
            result += byte
        }
        
        return result
    }
    
    private func frameTypeString(for type: WebSocketFrameType) -> String {
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
        var rightBarButtons: [UIBarButtonItem] = []
        
        // Copy payload button
        let copyButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(copyPayload)
        )
        copyButton.tintColor = .systemBlue
        rightBarButtons.append(copyButton)
        
        // Resend frame button (only for sent frames and if connection is active)
        if frame.direction == .sent && connection.isActive {
            let resendButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(showResendFrame)
            )
            resendButton.tintColor = .systemGreen
            rightBarButtons.append(resendButton)
        }
        
        navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    @objc private func copyPayload() {
        let currentText: String
        
        switch viewModeSegmentedControl.selectedSegmentIndex {
        case 0: // Pretty
            if let prettyJSON = frame.prettyPrintedJSON {
                currentText = prettyJSON
            } else {
                currentText = frame.payloadString ?? frame.hexDump
            }
        case 1: // Raw
            currentText = frame.payloadString ?? frame.hexDump
        case 2: // Hex
            currentText = frame.hexDump
        default:
            currentText = frame.payloadString ?? frame.hexDump
        }
        
        UIPasteboard.general.string = currentText
        
        showAlert(
            with: "Payload copied to clipboard",
            title: "Copied!"
        )
    }
    
    @objc private func showResendFrame() {
        let resendController = WebSocketResendFrameViewController(frame: frame, connection: connection)
        let navController = UINavigationController(rootViewController: resendController)
        present(navController, animated: true)
    }
} 