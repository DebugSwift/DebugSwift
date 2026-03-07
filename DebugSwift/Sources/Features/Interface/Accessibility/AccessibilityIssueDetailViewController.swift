//
//  AccessibilityIssueDetailViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 07/03/26.
//

import UIKit

final class AccessibilityIssueDetailViewController: BaseController {
    
    private let issue: AccessibilityIssue
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .black
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var severityView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var severityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private lazy var wcagLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        return label
    }()
    
    private lazy var sectionLabel: (String) -> UILabel = { text in
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.text = text
        return label
    }
    
    private lazy var bodyLabel: (String) -> UILabel = { text in
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.text = text
        return label
    }
    
    private lazy var codeView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .systemGreen
        textView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        textView.layer.cornerRadius = 8
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }()
    
    private lazy var copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Copy Code", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .black
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.addTarget(self, action: #selector(copyCodeTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var highlightButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Highlight Element", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(highlightElementTapped), for: .touchUpInside)
        return button
    }()
    
    init(issue: AccessibilityIssue) {
        self.issue = issue
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }
    
    private func setupUI() {
        title = issue.type.rawValue
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func configureContent() {
        var lastView: UIView?
        let padding: CGFloat = 20
        
        contentView.addSubview(severityView)
        severityView.addSubview(severityLabel)
        severityView.addSubview(wcagLabel)
        
        severityLabel.text = "\(issue.severity.emoji) Severity: \(issue.severity.rawValue)"
        wcagLabel.text = "WCAG Reference: \(issue.wcagReference)"
        
        NSLayoutConstraint.activate([
            severityView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            severityView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            severityView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            severityLabel.topAnchor.constraint(equalTo: severityView.topAnchor, constant: 12),
            severityLabel.leadingAnchor.constraint(equalTo: severityView.leadingAnchor, constant: 12),
            severityLabel.trailingAnchor.constraint(equalTo: severityView.trailingAnchor, constant: -12),
            
            wcagLabel.topAnchor.constraint(equalTo: severityLabel.bottomAnchor, constant: 4),
            wcagLabel.leadingAnchor.constraint(equalTo: severityView.leadingAnchor, constant: 12),
            wcagLabel.trailingAnchor.constraint(equalTo: severityView.trailingAnchor, constant: -12),
            wcagLabel.bottomAnchor.constraint(equalTo: severityView.bottomAnchor, constant: -12)
        ])
        
        lastView = severityView
        
        let elementLabel = sectionLabel("Element Details")
        contentView.addSubview(elementLabel)
        NSLayoutConstraint.activate([
            elementLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 24),
            elementLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            elementLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        lastView = elementLabel
        
        let elementText = """
        Type: \(issue.elementDescription)
        Location: \(issue.location.isEmpty ? "N/A" : issue.location)
        """
        let elementBodyLabel = bodyLabel(elementText)
        contentView.addSubview(elementBodyLabel)
        NSLayoutConstraint.activate([
            elementBodyLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
            elementBodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            elementBodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        lastView = elementBodyLabel
        
        let issueLabel = sectionLabel("Issue")
        contentView.addSubview(issueLabel)
        NSLayoutConstraint.activate([
            issueLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 24),
            issueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            issueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        lastView = issueLabel
        
        let issueBodyLabel = bodyLabel(issue.description)
        contentView.addSubview(issueBodyLabel)
        NSLayoutConstraint.activate([
            issueBodyLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
            issueBodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            issueBodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        lastView = issueBodyLabel
        
        let fixLabel = sectionLabel("How to Fix")
        contentView.addSubview(fixLabel)
        NSLayoutConstraint.activate([
            fixLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 24),
            fixLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            fixLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        lastView = fixLabel
        
        let fixBodyLabel = bodyLabel(issue.fixSuggestion)
        contentView.addSubview(fixBodyLabel)
        NSLayoutConstraint.activate([
            fixBodyLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
            fixBodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            fixBodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        lastView = fixBodyLabel
        
        if let codeExample = issue.codeExample {
            contentView.addSubview(codeView)
            codeView.text = codeExample
            
            NSLayoutConstraint.activate([
                codeView.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 12),
                codeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
                codeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
            ])
            lastView = codeView
            
            contentView.addSubview(copyButton)
            NSLayoutConstraint.activate([
                copyButton.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
                copyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
                copyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
                copyButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            lastView = copyButton
        }
        
        if issue.element != nil {
            contentView.addSubview(highlightButton)
            NSLayoutConstraint.activate([
                highlightButton.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 16),
                highlightButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
                highlightButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
                highlightButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            lastView = highlightButton
        }
        
        lastView?.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding).isActive = true
    }
    
    @objc private func copyCodeTapped() {
        if let code = issue.codeExample {
            UIPasteboard.general.string = code
            
            let alert = UIAlertController(
                title: "Copied!",
                message: "Code example copied to clipboard",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func highlightElementTapped() {
        guard let element = issue.element else { return }
        
        dismiss(animated: true) { [weak element] in
            AccessibilityHighlighter.shared.highlight(view: element)
        }
    }
}
