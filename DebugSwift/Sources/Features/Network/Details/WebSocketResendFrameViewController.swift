//
//  WebSocketResendFrameViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class WebSocketResendFrameViewController: BaseController {
    
    private let originalFrame: WebSocketFrame
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
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.text = "Edit the payload below and tap Send to resend this frame on the WebSocket connection."
        return label
    }()
    
    private let payloadTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .darkGray.withAlphaComponent(0.3)
        textView.textColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemBlue.cgColor
        return textView
    }()
    
    private let frameTypeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Text", "Binary"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.backgroundColor = .darkGray
        control.selectedSegmentTintColor = .systemBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()
    
    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = .right
        return label
    }()
    
    init(frame: WebSocketFrame, connection: WebSocketConnection) {
        self.originalFrame = frame
        self.connection = connection
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
        addNavigationButtons()
        setupKeyboardHandling()
    }
    
    private func setupUI() {
        title = "Resend Frame"
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(instructionLabel)
        contentView.addSubview(frameTypeSegmentedControl)
        contentView.addSubview(payloadTextView)
        contentView.addSubview(characterCountLabel)
        
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
            
            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Frame type control
            frameTypeSegmentedControl.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            frameTypeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            frameTypeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Payload text view
            payloadTextView.topAnchor.constraint(equalTo: frameTypeSegmentedControl.bottomAnchor, constant: 16),
            payloadTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            payloadTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            payloadTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            // Character count label
            characterCountLabel.topAnchor.constraint(equalTo: payloadTextView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            characterCountLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupContent() {
        // Set frame type
        frameTypeSegmentedControl.selectedSegmentIndex = originalFrame.type == .text ? 0 : 1
        
        // Set payload text
        if let payloadString = originalFrame.payloadString {
            payloadTextView.text = payloadString
        } else {
            // For binary data, show hex representation
            payloadTextView.text = originalFrame.hexDump
            frameTypeSegmentedControl.selectedSegmentIndex = 1
        }
        
        payloadTextView.delegate = self
        updateCharacterCount()
    }
    
    private func addNavigationButtons() {
        // Cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Send button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Send",
            style: .done,
            target: self,
            action: #selector(sendTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemGreen
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardFrame = keyboardSize.cgRectValue
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    @objc private func handleTapToDismissKeyboard() {
        dismissKeyboard()
    }
    
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func updateCharacterCount() {
        let count = payloadTextView.text.count
        characterCountLabel.text = "\(count) characters"
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendTapped() {
        guard !payloadTextView.text.isEmpty else {
            showAlert(
                with: "Please enter a payload to send",
                title: "Empty Payload"
            )
            return
        }
        
        guard connection.isActive else {
            showAlert(
                with: "The WebSocket connection is no longer active",
                title: "Connection Closed"
            )
            return
        }
        
        let isTextFrame = frameTypeSegmentedControl.selectedSegmentIndex == 0
        
        // Create the message
        let message: URLSessionWebSocketTask.Message
        
        if isTextFrame {
            message = .string(payloadTextView.text)
        } else {
            // For binary, try to parse hex or use text as UTF-8 data
            let data: Data
            let normalizedText = payloadTextView.text.components(separatedBy: .whitespacesAndNewlines).joined()
            if !normalizedText.isEmpty &&
                normalizedText.count.isMultiple(of: 2) &&
                normalizedText.allSatisfy({ $0.isHexDigit }) {
                data = Data(hexString: normalizedText) ?? payloadTextView.text.data(using: .utf8) ?? Data()
            } else {
                // Use as UTF-8 data
                data = payloadTextView.text.data(using: .utf8) ?? Data()
            }
            message = .data(data)
        }

        navigationItem.rightBarButtonItem?.isEnabled = false

        WebSocketMonitor.shared.sendMessage(message, onConnectionId: connection.id) { [weak self] result in
            guard let self else { return }
            self.navigationItem.rightBarButtonItem?.isEnabled = true

            switch result {
            case .success:
                self.showAlert(
                    with: "Frame sent successfully",
                    title: "Sent!"
                ) { [weak self] _ in
                    self?.dismiss(animated: true)
                }
            case .failure(let error):
                self.showAlert(
                    with: error.localizedDescription,
                    title: "Send Failed"
                )
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextViewDelegate

extension WebSocketResendFrameViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateCharacterCount()
    }
}

// MARK: - Data Extension for Hex Parsing

private extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        
        self = data
    }
}
