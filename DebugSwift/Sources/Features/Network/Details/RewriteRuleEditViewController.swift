//
//  RewriteRuleEditViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import UIKit

final class RewriteRuleEditViewController: BaseController {
    private let existingRule: ResponseBodyRewriteRule?
    private let onSave: (ResponseBodyRewriteRule) -> Void
    
    private lazy var patternField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "https://api.example.com/product/*"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private lazy var bodyTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .secondarySystemBackground
        textView.textColor = .label
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.separator.cgColor
        return textView
    }()
    
    init(rule: ResponseBodyRewriteRule?, onSave: @escaping (ResponseBodyRewriteRule) -> Void) {
        self.existingRule = rule
        self.onSave = onSave
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = existingRule == nil ? "Add Rewrite Rule" : "Edit Rewrite Rule"
        view.backgroundColor = .black
        
        let patternLabel = UILabel()
        patternLabel.translatesAutoresizingMaskIntoConstraints = false
        patternLabel.text = "URL Pattern"
        patternLabel.textColor = .white
        patternLabel.font = .preferredFont(forTextStyle: .headline)
        
        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = "Response Body"
        bodyLabel.textColor = .white
        bodyLabel.font = .preferredFont(forTextStyle: .headline)
        
        view.addSubview(patternLabel)
        view.addSubview(patternField)
        view.addSubview(bodyLabel)
        view.addSubview(bodyTextView)
        
        NSLayoutConstraint.activate([
            patternLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            patternLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            patternLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            patternField.topAnchor.constraint(equalTo: patternLabel.bottomAnchor, constant: 8),
            patternField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            patternField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            patternField.heightAnchor.constraint(equalToConstant: 44),
            
            bodyLabel.topAnchor.constraint(equalTo: patternField.bottomAnchor, constant: 16),
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            bodyTextView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            bodyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bodyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bodyTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        if let existingRule {
            patternField.text = existingRule.urlPattern
            bodyTextView.text = existingRule.responseBody
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    @objc private func saveTapped() {
        let pattern = (patternField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pattern.isEmpty else {
            showAlert(with: "URL pattern cannot be empty", title: "Error")
            return
        }
        
        let body = bodyTextView.text ?? ""
        let rule = ResponseBodyRewriteRule(urlPattern: pattern, responseBody: body)
        onSave(rule)
        navigationController?.popViewController(animated: true)
    }
}
