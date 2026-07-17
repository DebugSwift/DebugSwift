//
//  ContrastCheckerViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois (Contrast Checker) on 16/07/26.
//

import UIKit

// MARK: - Color Contrast Checker

/// Interactive screen for checking WCAG contrast between two hex colors,
/// plus a "Screenshot Audit" mode that scans the current screen for failing
/// text/background pairs and overlays red circles on violations.
final class ContrastCheckerViewController: BaseController {

    // MARK: - Subviews

    private let foregroundField = UITextField()
    private let backgroundField = UITextField()
    private let checkButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private let stackView = UIStackView()
    private let auditButton = UIButton(type: .system)

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

        auditButton.setTitle("Audit Screenshot", for: .normal)
        auditButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        auditButton.addTarget(self, action: #selector(auditTapped), for: .touchUpInside)
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
        stackView.addArrangedSubview(auditButton)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            foregroundField.heightAnchor.constraint(equalToConstant: 44),
            backgroundField.heightAnchor.constraint(equalToConstant: 44),
            checkButton.heightAnchor.constraint(equalToConstant: 44),
            auditButton.heightAnchor.constraint(equalToConstant: 44)
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

    @objc private func auditTapped() {
        view.endEditing(true)

        // Find the app's main window (not the DebugSwift CustomWindow overlay)
        let appWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { !$0.isHidden && !String(describing: type(of: $0)).contains("CustomWindow") && $0.rootViewController != nil }

        guard let window = appWindow else {
            resultLabel.text = "No app window found to audit"
            resultLabel.textColor = .systemRed
            return
        }

        // Hide the DebugSwift overlay window so it doesn't appear in the capture
        let debugWindow = WindowManager.window
        debugWindow.isHidden = true

        // Force a layout pass on the app window so it renders fresh content
        window.layoutIfNeeded()

        // Snapshot the app window content
        let bounds = window.bounds
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let snapshot = renderer.image { _ in
            window.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }

        // Restore the debug overlay
        debugWindow.isHidden = false

        let findings = ContrastAuditor.audit(window: window)
        let annotatedImage = ContrastAuditor.render(
            image: snapshot,
            bounds: bounds,
            findings: findings
        )

        let resultVC = ContrastAuditResultViewController(image: annotatedImage, findings: findings)
        navigationController?.pushViewController(resultVC, animated: true)
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

// MARK: - Contrast Auditor

/// Scans the view hierarchy for text elements and checks their contrast
/// against the effective background color.
enum ContrastAuditor {

    struct Finding {
        let frame: CGRect
        let text: String
        let textColor: UIColor
        let backgroundColor: UIColor
        let ratio: Double
        let grade: ContrastGrade
    }
    @MainActor
    static func audit(window: UIWindow) -> [Finding] {
        var findings: [Finding] = []
        enumerateTextElements(in: window, window: window) { view, textColor, text in
            let bgColor = effectiveBackgroundColor(for: view)
            let ratio = ContrastAdapter.ratio(foreground: textColor, background: bgColor)
            let grade = ContrastChecker.grade(ratio)

            if grade == .fail {
                findings.append(Finding(
                    frame: view.convert(view.bounds, to: window),
                    text: text,
                    textColor: textColor,
                    backgroundColor: bgColor,
                    ratio: ratio,
                    grade: grade
                ))
            }
        }
        return findings
    }

    @MainActor
    private static func enumerateTextElements(
        in view: UIView,
        window: UIWindow,
        callback: (UIView, UIColor, String) -> Void
    ) {
        if let label = view as? UILabel, let text = label.text, !text.isEmpty, let textColor = label.textColor {
            callback(label, textColor, text)
            return
        }

        if let textView = view as? UITextView, let text = textView.text, !text.isEmpty, let textColor = textView.textColor {
            callback(textView, textColor, text)
            return
        }

        if let button = view as? UIButton, let title = button.title(for: .normal), !title.isEmpty, let textColor = button.titleColor(for: .normal) {
            callback(button, textColor, title)
            return
        }

        for subview in view.subviews {
            enumerateTextElements(in: subview, window: window, callback: callback)
        }
    }

    /// Walk up the superview chain to find the first opaque background color.
    private static func effectiveBackgroundColor(for view: UIView) -> UIColor {
        var current: UIView? = view
        while let parent = current {
            if let bg = parent.backgroundColor, bg.cgColor.alpha > 0.5 {
                return bg
            }
            current = parent.superview
        }
        return .white
    }

    /// Render the snapshot with red circles on failing elements.
    static func render(
        image: UIImage,
        bounds: CGRect,
        findings: [Finding]
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { _ in
            image.draw(in: bounds)

            for finding in findings {
                let center = CGPoint(x: finding.frame.midX, y: finding.frame.midY)
                let radius = max(finding.frame.width, finding.frame.height) / 2 + 8
                let rect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )

                let circle = UIBezierPath(ovalIn: rect)
                UIColor.systemRed.setStroke()
                circle.lineWidth = 3
                circle.stroke()

                let dotRect = CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)
                let dot = UIBezierPath(ovalIn: dotRect)
                UIColor.systemRed.setFill()
                dot.fill()
            }
        }
    }
}

// MARK: - Audit Result View Controller

final class ContrastAuditResultViewController: UIViewController {

    private let image: UIImage
    private let findings: [ContrastAuditor.Finding]

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let descriptionLabel = UILabel()

    init(image: UIImage, findings: [ContrastAuditor.Finding]) {
        self.image = image
        self.findings = findings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audit Result"
        view.backgroundColor = .black

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .white
        descriptionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.layer.cornerRadius = 8
        descriptionLabel.layer.masksToBounds = true

        if findings.isEmpty {
            descriptionLabel.text = "No contrast issues found — all text elements meet WCAG AA (ratio >= 4.5:1)."
        } else {
            let lines = findings.enumerated().map { index, finding in
                String(format: "%d. \"%@\" — ratio %.2f:1 (needs ≥ 4.5:1)\n   text: %@  background: %@",
                       index + 1,
                       String(finding.text.prefix(40)),
                       finding.ratio,
                       hexString(from: finding.textColor),
                       hexString(from: finding.backgroundColor)
                )
            }
            descriptionLabel.text = "\(findings.count) contrast issue(s) found:\n\n" + lines.joined(separator: "\n\n")
        }

        view.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            descriptionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
