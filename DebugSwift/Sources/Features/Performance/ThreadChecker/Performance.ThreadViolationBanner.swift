//
//  Performance.ThreadViolationBanner.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class ThreadViolationBanner: UIView {
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        return view
    }()
    
    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.text = "Main Thread Violation"
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("✕", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()
    
    // MARK: - Properties
    
    private let violation: PerformanceThreadChecker.ThreadViolation
    
    // MARK: - Initialization
    
    init(violation: PerformanceThreadChecker.ThreadViolation) {
        self.violation = violation
        super.init(frame: .zero)
        setupUI()
        configureForViolation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(stackView)
        containerView.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Icon
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),
            
            // Stack view
            stackView.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -8),
            
            // Dismiss button
            dismissButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dismissButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Add subtle animation on appearance
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -50)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    private func configureForViolation() {
        iconLabel.text = violation.severity.emoji
        containerView.layer.borderColor = violation.severity.color.cgColor
        
        subtitleLabel.text = "\(violation.methodName) called on \(violation.threadName)"
        
        // Add tap gesture to show details
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bannerTapped))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func dismissTapped() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -20)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func bannerTapped() {
        // Show detailed violation information
        showDetailedAlert()
    }
    
    private func showDetailedAlert() {
        guard let viewController = findViewController() else { return }
        
        let alert = UIAlertController(
            title: "\(violation.severity.emoji) Thread Violation Details",
            message: """
            Method: \(violation.methodName)
            Class: \(violation.className)
            Thread: \(violation.threadName)
            Severity: \(violation.severity.rawValue)
            Time: \(DateFormatter.localizedString(from: violation.timestamp, dateStyle: .none, timeStyle: .medium))
            
            Stack Trace (first 3 frames):
            \(violation.stackTrace.prefix(3).joined(separator: "\n"))
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        alert.addAction(UIAlertAction(title: "Copy Stack Trace", style: .default) { _ in
            UIPasteboard.general.string = self.violation.stackTrace.joined(separator: "\n")
        })
        
        viewController.present(alert, animated: true)
    }
}

// MARK: - Helper Extensions

private extension UIView {
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
} 