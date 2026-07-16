//
//  ContrastCheckerViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois (Contrast Checker) on 16/07/26.
//

import UIKit

// MARK: - Color Contrast Checker

/// Interactive screen for checking WCAG contrast between two hex colors.
/// Delegates all WCAG math to `ContrastAdapter`; this view only owns the UI.
final class ContrastCheckerViewController: BaseController {

    // MARK: - Subviews

    private let foregroundField = UITextField()
    private let backgroundField = UITextField()
    private let checkButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private let stackView = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Color Contrast"
        setupSubviews()
        setupLayout()
    }

    // MARK: - Setup

    private func setupSubviews() {
        view.backgroundColor = .systemBackground

        configureHexField(foregroundField, placeholder: "#000000")
        configureHexField(backgroundField, placeholder: "#FFFFFF")

        checkButton.setTitle("Check Contrast", for: .normal)
        checkButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)

        resultLabel.numberOfLines = 0
        resultLabel.font = .systemFont(ofSize: 16, weight: .medium)
        resultLabel.textAlignment = .center
        resultLabel.text = "Enter two hex colors to check WCAG contrast"
    }

    private func configureHexField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .allCharacters
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.keyboardType = .asciiCapable
        field.font = .systemFont(ofSize: 16, weight: .medium)
        field.textAlignment = .center
        field.delegate = self
    }

    private func setupLayout() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(foregroundField)
        stackView.addArrangedSubview(backgroundField)
        stackView.addArrangedSubview(checkButton)
        stackView.addArrangedSubview(resultLabel)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            foregroundField.heightAnchor.constraint(equalToConstant: 44),
            backgroundField.heightAnchor.constraint(equalToConstant: 44),
            checkButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Actions

    @objc private func checkTapped() {
        view.endEditing(true)

        guard let foreground = UIColor(hex: foregroundField.text),
              let background = UIColor(hex: backgroundField.text) else {
            resultLabel.text = "Invalid hex color"
            resultLabel.textColor = .systemRed
            return
        }

        resultLabel.text = ContrastAdapter.report(foreground: foreground, background: background)
        resultLabel.textColor = .label
    }
}

// MARK: - UITextFieldDelegate

extension ContrastCheckerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Hex parsing

private extension UIColor {
    /// Parses a hex string (`#RRGGBB`, `RRGGBB`, `#RGB`, or `RGB`) into a `UIColor`.
    /// Returns `nil` when the string is not a valid 3- or 6-digit hex color.
    convenience init?(hex: String?) {
        let trimmed = (hex ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        let hexValue: String
        if trimmed.count == 3 {
            hexValue = trimmed.map { "\($0)\($0)" }.joined()
        } else {
            hexValue = trimmed
        }

        guard hexValue.count == 6,
              let value = UInt32(hexValue, radix: 16) else { return nil }

        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
