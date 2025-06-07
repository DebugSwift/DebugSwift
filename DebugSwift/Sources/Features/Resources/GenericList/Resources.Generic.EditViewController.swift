//
//  Resources.Generic.EditViewController.swift
//  DebugSwift
//
//  Created by DebugSwift on 01/01/25.
//

import UIKit

@MainActor
protocol ResourcesGenericEditDelegate: AnyObject {
    func didSaveItem(key: String, value: String, originalKey: String?)
}

final class ResourcesGenericEditViewController: BaseController {
    
    weak var delegate: ResourcesGenericEditDelegate?
    
    private let isEditMode: Bool
    private let originalKey: String?
    private let originalValue: String?
    private let keyPlaceholder: String
    private let valuePlaceholder: String
    private let viewTitle: String
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .black
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var keyTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        textField.font = .systemFont(ofSize: 16)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .next
        textField.delegate = self
        return textField
    }()
    
    private lazy var valueTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .secondarySystemBackground
        textView.textColor = .label
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.delegate = self
        return textView
    }()
    
    private lazy var keyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Key"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        return label
    }()
    
    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Value"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        return label
    }()
    
    init(
        key: String? = nil,
        value: String? = nil,
        keyPlaceholder: String = "Enter key",
        valuePlaceholder: String = "Enter value",
        title: String = "Add Item"
    ) {
        self.isEditMode = key != nil
        self.originalKey = key
        self.originalValue = value
        self.keyPlaceholder = keyPlaceholder
        self.valuePlaceholder = valuePlaceholder
        self.viewTitle = title
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
        
        if isEditMode {
            keyTextField.text = originalKey
            keyTextField.isEnabled = false
            keyTextField.alpha = 0.6
            
            valueTextView.text = originalValue
            valueTextView.textColor = .label
        } else {
            valueTextView.text = valuePlaceholder
            valueTextView.textColor = .placeholderText
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(keyLabel)
        contentView.addSubview(keyTextField)
        contentView.addSubview(valueLabel)
        contentView.addSubview(valueTextView)
        
        keyTextField.placeholder = keyPlaceholder
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            keyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            keyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            keyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            keyTextField.topAnchor.constraint(equalTo: keyLabel.bottomAnchor, constant: 8),
            keyTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            keyTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            keyTextField.heightAnchor.constraint(equalToConstant: 44),
            
            valueLabel.topAnchor.constraint(equalTo: keyTextField.bottomAnchor, constant: 20),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            valueTextView.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            valueTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            valueTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            valueTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            valueTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupNavigationBar() {
        title = viewTitle
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    private func setupKeyboardObservers() {
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
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.verticalScrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let key = keyTextField.text, !key.isEmpty else {
            showAlert(with: "Error", title: "Key cannot be empty")
            return
        }
        
        let value = (valueTextView.textColor == .placeholderText || valueTextView.text == valuePlaceholder) ? "" : (valueTextView.text ?? "")
        
        delegate?.didSaveItem(key: key, value: value, originalKey: originalKey)
        dismiss(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension ResourcesGenericEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == keyTextField {
            valueTextView.becomeFirstResponder()
        }
        return true
    }
}

// MARK: - UITextViewDelegate
extension ResourcesGenericEditViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText && textView.text == valuePlaceholder {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = valuePlaceholder
            textView.textColor = .placeholderText
        }
    }
} 