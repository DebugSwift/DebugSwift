//
//  AgentDebugLogViewController.swift
//  DebugSwift
//
//  Screen that exposes the aggregated `agent-debug.ndjson` log to the user
//  and to an AI agent. Shows a copyable description (where the log lives,
//  how to pull it, the NDJSON schema) and a toggle for the underlying
//  beta feature.
//

import UIKit

final class AgentDebugLogViewController: BaseController {

    // MARK: - State

    private let log = AgentDebugLog.shared

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        return stackView
    }()

    private let toggleSwitch = UISwitch()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        return label
    }()

    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
        return textView
    }()

    private let pathLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupViews()
        refresh()
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "Agent Debug Log"
        navigationItem.largeTitleDisplayMode = .never

        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        let copyButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(copyDescriptionTapped)
        )
        navigationItem.rightBarButtonItems = [shareButton, copyButton]
    }

    private func setupViews() {
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        // Toggle row
        let toggleRow = makeToggleRow()
        stackView.addArrangedSubview(toggleRow)

        // Section header: What is this?
        stackView.addArrangedSubview(makeSectionHeader("What is this?"))
        stackView.addArrangedSubview(makeBodyLabel(
            "When enabled, DebugSwift aggregates network logs, crashes, " +
            "console output, and debug events into a single NDJSON file " +
            "an AI agent (Cursor DEBUG MODE, XcodeBazelMCP) can pull and " +
            "reason about. Toggle it on, reproduce your bug, then copy the " +
            "description below and hand it to your AI agent."
        ))

        // Section header: Log path
        stackView.addArrangedSubview(makeSectionHeader("Log path"))
        stackView.addArrangedSubview(pathLabel)

        // Section header: AI agent instructions (copyable)
        stackView.addArrangedSubview(makeSectionHeader("AI agent instructions (copy this)"))
        stackView.addArrangedSubview(descriptionTextView)

        // Section header: Actions
        stackView.addArrangedSubview(makeSectionHeader("Actions"))
        stackView.addArrangedSubview(makeActionButton("Copy instructions", action: #selector(copyDescriptionTapped)))
        stackView.addArrangedSubview(makeActionButton("Share log file", action: #selector(shareTapped)))
        stackView.addArrangedSubview(makeActionButton("Clear log", action: #selector(clearTapped)))
        stackView.addArrangedSubview(makeActionButton("Refresh", action: #selector(refreshTapped)))
    }

    private func makeToggleRow() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Agent Debug Log"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Aggregate debug data for AI agents"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.numberOfLines = 0

        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.onTintColor = UIColor(hexString: "#42d459") ?? .systemGreen
        toggleSwitch.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(toggleSwitch)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: toggleSwitch.leadingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: toggleSwitch.leadingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            toggleSwitch.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toggleSwitch.widthAnchor.constraint(equalToConstant: 60)
        ])

        return container
    }

    private func makeSectionHeader(_ text: String) -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text.uppercased()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = UIColor(hexString: "#42d459") ?? .systemGreen
        label.accessibilityTraits = .header
        let top = UIView()
        top.translatesAutoresizingMaskIntoConstraints = false
        top.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: top.topAnchor),
            label.leadingAnchor.constraint(equalTo: top.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: top.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: top.bottomAnchor)
        ])
        return top
    }

    private func makeBodyLabel(_ text: String) -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        return label
    }

    private func makeActionButton(_ title: String, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        button.layer.cornerRadius = 8
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }

    // MARK: - Refresh

    private func refresh() {
        let enabled = log.enabled
        toggleSwitch.setOn(enabled, animated: false)
        statusLabel.text = enabled ? "Capture: ON" : "Capture: OFF"
        pathLabel.text = log.currentLogPath().path
        descriptionTextView.text = log.agentDescription
    }

    // MARK: - Actions

    @objc private func toggleChanged(_ sender: UISwitch) {
        if sender.isOn {
            FeatureHandling.enabledBetaFeatures.append(.agentDebugLog)
            log.enable()
        } else {
            FeatureHandling.enabledBetaFeatures.removeAll(where: { $0 == .agentDebugLog })
            log.disable()
        }
        refresh()
    }

    @objc private func copyDescriptionTapped() {
        UIPasteboard.general.string = log.agentDescription
        showToast(message: "Instructions copied to clipboard")
    }

    @objc private func shareTapped() {
        let path = log.currentLogPath().path
        let url = URL(fileURLWithPath: path)
        let activityVC: UIActivityViewController
        if FileManager.default.fileExists(atPath: path) {
            activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        } else {
            activityVC = UIActivityViewController(
                activityItems: [log.agentDescription],
                applicationActivities: nil
            )
        }
        if let pop = activityVC.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(activityVC, animated: true)
    }

    @objc private func clearTapped() {
        log.clear()
        showToast(message: "Log cleared")
        refresh()
    }

    @objc private func refreshTapped() {
        refresh()
    }

    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
