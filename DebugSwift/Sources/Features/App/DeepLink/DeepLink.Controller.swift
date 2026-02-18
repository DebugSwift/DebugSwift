//
//  DeepLink.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 13/02/26.
//

import UIKit

final class DeepLinkViewController: BaseController {
    
    // MARK: - Properties
    
    private let viewModel = DeepLinkViewModel()
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var urlTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter DeepLink URL (debugswift://test or https://...)"
        textField.borderStyle = .none
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .URL
        textField.returnKeyType = .go
        textField.delegate = self
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 15)
        return textField
    }()
    
    private lazy var testButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Test Deep Link", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var quickTestLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Quick Test URLs"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private lazy var quickTestStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var historyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Recent History"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private lazy var clearHistoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(clearHistoryTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DeepLinkHistoryCell.self, forCellReuseIdentifier: "DeepLinkHistoryCell")
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No deep links tested yet.\nTry testing a URL above!"
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Deep Links"
        view.backgroundColor = .black
        
        setupUI()
        setupQuickTestButtons()
        setupKeyboardObservers()
        
        viewModel.onHistoryUpdated = { [weak self] in
            self?.updateHistoryUI()
        }
        
        updateHistoryUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(inputContainerView)
        inputContainerView.addSubview(urlTextField)
        contentView.addSubview(testButton)
        contentView.addSubview(quickTestLabel)
        contentView.addSubview(quickTestStackView)
        contentView.addSubview(historyLabel)
        contentView.addSubview(clearHistoryButton)
        contentView.addSubview(tableView)
        contentView.addSubview(emptyStateLabel)
        
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
            
            inputContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            inputContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inputContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            inputContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            urlTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            urlTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            urlTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            urlTextField.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            
            testButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 12),
            testButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            testButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            testButton.heightAnchor.constraint(equalToConstant: 50),
            
            quickTestLabel.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 24),
            quickTestLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickTestLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            quickTestStackView.topAnchor.constraint(equalTo: quickTestLabel.bottomAnchor, constant: 12),
            quickTestStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickTestStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            historyLabel.topAnchor.constraint(equalTo: quickTestStackView.bottomAnchor, constant: 24),
            historyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            clearHistoryButton.centerYAnchor.constraint(equalTo: historyLabel.centerYAnchor),
            clearHistoryButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableView.heightAnchor.constraint(equalToConstant: 400),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -20),
            
            contentView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20)
        ])
    }
    
    private func setupQuickTestButtons() {
        let urls = viewModel.getQuickTestURLs()
        
        for urlString in urls {
            let button = createQuickTestButton(urlString: urlString)
            quickTestStackView.addArrangedSubview(button)
        }
    }
    
    private func createQuickTestButton(urlString: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(urlString, for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .leading
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: #selector(quickTestButtonTapped(_:)), for: .touchUpInside)
        return button
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
    
    // MARK: - Actions
    
    @objc private func testButtonTapped() {
        guard let urlString = urlTextField.text?.trimmingCharacters(in: .whitespaces), !urlString.isEmpty else {
            showAlert(with: "Empty URL", title: "Please enter a URL to test")
            return
        }
        
        testDeepLink(urlString)
    }
    
    @objc private func quickTestButtonTapped(_ sender: UIButton) {
        guard let urlString = sender.title(for: .normal) else { return }
        urlTextField.text = urlString
        testDeepLink(urlString)
    }
    
    @objc private func clearHistoryTapped() {
        showAlert(
            with: "Clear History",
            title: "Are you sure you want to clear all deep link history?",
            leftButtonTitle: "Clear",
            leftButtonStyle: .destructive,
            leftButtonHandler: { [weak self] _ in
                self?.viewModel.clearHistory()
            },
            rightButtonTitle: "Cancel",
            rightButtonStyle: .cancel
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Private Methods
    
    private func testDeepLink(_ urlString: String) {
        view.endEditing(true)
        
        viewModel.openDeepLink(urlString) { [weak self] success, errorMessage in
            DispatchQueue.main.async {
                if let errorMessage = errorMessage {
                    self?.showAlert(with: "Deep Link Error", title: errorMessage)
                }
            }
        }
    }
    
    private func updateHistoryUI() {
        let hasHistory = !viewModel.history.isEmpty
        emptyStateLabel.isHidden = hasHistory
        tableView.isHidden = !hasHistory
        clearHistoryButton.isHidden = !hasHistory
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension DeepLinkViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DeepLinkHistoryCell", for: indexPath) as? DeepLinkHistoryCell else {
            return UITableViewCell()
        }
        
        let entry = viewModel.history[indexPath.row]
        cell.configure(with: entry)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension DeepLinkViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let entry = viewModel.history[indexPath.row]
        if let url = entry.url {
            urlTextField.text = url.absoluteString
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteEntry(at: indexPath.row)
        }
    }
}

// MARK: - UITextFieldDelegate

extension DeepLinkViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        testButtonTapped()
        return true
    }
}

// MARK: - DeepLinkHistoryCell

private final class DeepLinkHistoryCell: UITableViewCell {
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24)
        return label
    }()
    
    private let urlLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11)
        label.textColor = .systemBlue
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
        backgroundColor = .black
        
        contentView.addSubview(statusLabel)
        contentView.addSubview(urlLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(typeLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 30),
            
            urlLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            urlLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 12),
            urlLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            timestampLabel.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 12),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            typeLabel.centerYAnchor.constraint(equalTo: timestampLabel.centerYAnchor),
            typeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }
    
    func configure(with entry: DeepLinkEntry) {
        statusLabel.text = entry.statusIcon
        urlLabel.text = entry.urlString
        timestampLabel.text = entry.formattedTimestamp
        typeLabel.text = entry.type
    }
}
