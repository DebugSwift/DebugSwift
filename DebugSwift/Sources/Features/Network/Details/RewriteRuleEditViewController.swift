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
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.separator.cgColor
        return textView
    }()

    private lazy var statusCodeField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Optional (e.g. 404)"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        textField.keyboardType = .numberPad
        return textField
    }()
    
    private let supportedHTTPMethods = HTTPMethod.allCases
    private var selectedHTTPMethod: HTTPMethod?
    private weak var methodButton: UIButton!
    private var initialDraftRule: ResponseBodyRewriteRule?
    private var showPopup = false
    
    init(rule: ResponseBodyRewriteRule?, onSave: @escaping (ResponseBodyRewriteRule) -> Void) {
        self.existingRule = rule
        self.onSave = onSave
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationInterception()
        captureInitialState()
    }
    
    private func setupUI() {
        title = "Response Editor"
        view.backgroundColor = .black
        
        func makeSectionLabel(_ title: String) -> UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = title
            label.textColor = .white
            label.font = .preferredFont(forTextStyle: .headline)
            return label
        }
        
        let methodButton = UIButton(type: .system)
        methodButton.translatesAutoresizingMaskIntoConstraints = false
        methodButton.setTitleColor(.systemBlue, for: .normal)
        methodButton.contentHorizontalAlignment = .left
        methodButton.layer.cornerRadius = 8
        methodButton.layer.borderWidth = 0.5
        methodButton.layer.borderColor = UIColor.separator.cgColor
        methodButton.backgroundColor = .secondarySystemBackground
        methodButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        if #available(iOS 14.0, *) {
            methodButton.showsMenuAsPrimaryAction = true
        } else {
            methodButton.addTarget(self, action: #selector(selectMethodTappedLegacy), for: .touchUpInside)
        }
        
        self.methodButton = methodButton
        updateMethodSelection()

        let patternSection = UIStackView(arrangedSubviews: [
            makeSectionLabel("URL or Pattern"),
            patternField,
        ])
        patternSection.axis = .vertical
        patternSection.spacing = 8

        let statusCodeSection = UIStackView(arrangedSubviews: [
            makeSectionLabel("Status Code"),
            statusCodeField,
        ])
        statusCodeSection.axis = .vertical
        statusCodeSection.spacing = 8

        let methodSection = UIStackView(arrangedSubviews: [
            makeSectionLabel("HTTP Method"),
            methodButton,
        ])
        methodSection.axis = .vertical
        methodSection.spacing = 8

        let bodySection = UIStackView(arrangedSubviews: [
            makeSectionLabel("Response Body"),
            bodyTextView,
        ])
        bodySection.axis = .vertical
        bodySection.spacing = 8
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let formStack = UIStackView(arrangedSubviews: [
            patternSection,
            statusCodeSection,
            methodSection,
            bodySection,
        ])
        formStack.translatesAutoresizingMaskIntoConstraints = false
        formStack.axis = .vertical
        formStack.spacing = 16
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(formStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            formStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            patternField.heightAnchor.constraint(equalToConstant: 44),
            statusCodeField.heightAnchor.constraint(equalToConstant: 44),
            methodButton.heightAnchor.constraint(equalToConstant: 44),
            bodyTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320)
        ])
        
        if let existingRule {
            patternField.text = existingRule.urlPattern
            bodyTextView.text = existingRule.responseBody
            selectedHTTPMethod = existingRule.httpMethod
            updateMethodSelection()
            if let responseStatusCode = existingRule.responseStatusCode {
                statusCodeField.text = "\(responseStatusCode)"
            }
        }
        
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showBodyEditorOptions)
        )
        let bodyEditorButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(openBodyEditorTapped)
        )
        bodyEditorButton.accessibilityLabel = "Body Editor"
        navigationItem.rightBarButtonItems = [saveButton, bodyEditorButton, menuButton]
    }

    private func setupNavigationInterception() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    private func captureInitialState() {
        initialDraftRule = currentDraftRule()
    }

    private func hasUnsavedChanges() -> Bool {
        currentDraftRule() != initialDraftRule
    }

    private func currentDraftRule() -> ResponseBodyRewriteRule {
        let pattern = (patternField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let statusCodeText = (statusCodeField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let statusCode: Int? = Int(statusCodeText)
        return ResponseBodyRewriteRule(
            urlPattern: pattern,
            responseBody: bodyTextView.text ?? "",
            responseStatusCode: statusCode,
            httpMethod: selectedHTTPMethod
        )
    }
    
    @objc private func openBodyEditorTapped() {
        openKeyValueEditor()
    }

    @objc private func showBodyEditorOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Clear Body", style: .destructive) { [weak self] _ in
            self?.bodyTextView.text = ""
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(alert, animated: true)
    }

    @objc private func backTapped() {
        guard hasUnsavedChanges() else {
            showPopup = true
            navigationController?.popViewController(animated: true)
            return
        }

        let alert = UIAlertController(
            title: "Unsaved Changes",
            message: "You have unsaved changes. Discard them and go back?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.showPopup = true
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func updateMethodSelection() {
        let title = selectedHTTPMethod?.rawValue ?? "All Methods"
        methodButton.setTitle(title, for: .normal)
        if #available(iOS 14.0, *) {
            methodButton.menu = buildMethodMenu()
        }
    }

    private func buildMethodMenu() -> UIMenu {
        var actions: [UIAction] = []
        actions.append(
            UIAction(
                title: "All Methods",
                state: selectedHTTPMethod == nil ? .on : .off
            ) { [weak self] _ in
                self?.selectedHTTPMethod = nil
                self?.updateMethodSelection()
            }
        )
        actions.append(contentsOf: supportedHTTPMethods.map { method in
            UIAction(
                title: method.rawValue,
                state: selectedHTTPMethod == method ? .on : .off
            ) { [weak self] _ in
                self?.selectedHTTPMethod = method
                self?.updateMethodSelection()
            }
        })
        return UIMenu(title: "HTTP Method", options: .displayInline, children: actions)
    }

    @objc private func selectMethodTappedLegacy() {
        let alert = UIAlertController(title: "HTTP Method", message: "Select one method", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "All Methods", style: .default) { [weak self] _ in
            self?.selectedHTTPMethod = nil
            self?.updateMethodSelection()
        })
        for method in supportedHTTPMethods {
            alert.addAction(UIAlertAction(title: method.rawValue, style: .default) { [weak self] _ in
                self?.selectedHTTPMethod = method
                self?.updateMethodSelection()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = methodButton
            popover.sourceRect = methodButton.bounds
        }
        present(alert, animated: false)
    }
    
    private func openKeyValueEditor() {
        let body = (bodyTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "{}"
            : (bodyTextView.text ?? "")
        guard let editor = BodyEditorViewController(body: body, onSave: { [weak self] updatedJSON in
            self?.bodyTextView.text = updatedJSON
        }) else {
            showInvalidJSONAlert()
            return
        }
        
        navigationController?.pushViewController(editor, animated: true)
    }
    
    @objc private func saveTapped() {
        let pattern = (patternField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pattern.isEmpty else {
            showAlert(with: "URL pattern cannot be empty", title: "Error")
            return
        }
        
        let statusCodeText = (statusCodeField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let statusCode: Int?
        if statusCodeText.isEmpty {
            statusCode = nil
        } else if let parsedStatusCode = Int(statusCodeText), (100...599).contains(parsedStatusCode) {
            statusCode = parsedStatusCode
        } else {
            showAlert(with: "Status code must be between 100 and 599", title: "Error")
            return
        }
        
        let body = bodyTextView.text ?? ""
        
        let rule = ResponseBodyRewriteRule(
            urlPattern: pattern,
            responseBody: body,
            responseStatusCode: statusCode,
            httpMethod: selectedHTTPMethod
        )
        onSave(rule)
        captureInitialState()
        showPopup = true
        navigationController?.popViewController(animated: true)
    }
    
    private func showInvalidJSONAlert() {
        showAlert(with: "Body must be a valid JSON object or array", title: "Invalid JSON")
    }
}
