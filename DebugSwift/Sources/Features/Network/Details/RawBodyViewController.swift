//
//  RawBodyViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 14/01/26.
//

import UIKit

final class RawBodyViewController: BaseController {
    private let data: Data?
    private let headers: [String: Any]?
    private let bodyTitle: String
    private let isRequest: Bool
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .black
        textView.textColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        return textView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    init(data: Data?, headers: [String: Any]?, title: String, isRequest: Bool) {
        self.data = data
        self.headers = headers
        self.bodyTitle = title
        self.isRequest = isRequest
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadContent()
    }
    
    private func setupUI() {
        title = bodyTitle
        view.backgroundColor = .black
        
        view.addSubview(textView)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add long press gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        textView.addGestureRecognizer(longPress)
        
        // Add copy button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(showCopyOptions)
        )
    }
    
    private func loadContent() {
        // For large data, load asynchronously
        let totalSize = (data?.count ?? 0) + estimatedHeadersSize()
        
        if totalSize > 100_000 {
            loadingIndicator.startAnimating()
            textView.isHidden = true
            
            let capturedData = data
            // Convert to Sendable array of tuples
            let capturedHeaders = headers?.map { ($0.key, "\($0.value)") } ?? []
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let formatted = Self.formatRawWithHeaders(data: capturedData, headers: capturedHeaders)
                
                DispatchQueue.main.async {
                    self?.textView.text = formatted
                    self?.textView.isHidden = false
                    self?.loadingIndicator.stopAnimating()
                }
            }
        } else {
            let headersArray = headers?.map { ($0.key, "\($0.value)") } ?? []
            textView.text = Self.formatRawWithHeaders(data: data, headers: headersArray)
        }
    }
    
    nonisolated private static func formatRawWithHeaders(data: Data?, headers: [(String, String)]) -> String {
        var result = ""
        
        // Add headers section
        if !headers.isEmpty {
            result += "Headers:\n"
            result += String(repeating: "─", count: 60) + "\n"
            
            let sortedHeaders = headers.sorted { $0.0.lowercased() < $1.0.lowercased() }
            for (key, value) in sortedHeaders {
                result += "\(key): \(value)\n"
            }
            result += "\n"
        }
        
        // Add body section
        result += "Body:\n"
        result += String(repeating: "─", count: 60) + "\n"
        
        if let data = data, !data.isEmpty {
            result += data.formattedString()
        } else {
            result += "No data"
        }
        
        return result
    }
    
    private func estimatedHeadersSize() -> Int {
        Self.calculateHeadersSize(headers)
    }
    
    private static func calculateHeadersSize(_ headers: [String: Any]?) -> Int {
        guard let headers = headers else { return 0 }
        return headers.reduce(0) { $0 + $1.key.count + "\($1.value)".count }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        // If there's a text selection, copy that. Otherwise copy all
        if let selectedRange = textView.selectedTextRange,
           !selectedRange.isEmpty,
           let selectedText = textView.text(in: selectedRange) {
            UIPasteboard.general.string = selectedText
        } else {
            UIPasteboard.general.string = textView.text
        }
        
        showCopyConfirmation()
    }
    
    @objc private func showCopyOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let rawTitle = isRequest ? "Copy Raw Request" : "Copy Raw Response"
        
        alert.addAction(UIAlertAction(title: rawTitle, style: .default) { [weak self] _ in
            self?.copyRawContent()
        })
        
        alert.addAction(UIAlertAction(title: "Copy JSON Body", style: .default) { [weak self] _ in
            self?.copyJSONBody()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func copyRawContent() {
        UIPasteboard.general.string = textView.text
        showCopyConfirmation()
    }
    
    private func copyJSONBody() {
        let body = data?.formattedString() ?? "No data"
        UIPasteboard.general.string = body
        showCopyConfirmation()
    }
    
    private func showCopyConfirmation() {
        let alert = UIAlertController(title: nil, message: "Copied to clipboard", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
}
