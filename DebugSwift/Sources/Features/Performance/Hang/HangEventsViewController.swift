//
//  HangEventsViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois (ANR Detection) on 17/07/26.
//

import UIKit

/// Lists recorded hang/ANR events (newest first) with timestamp, duration,
/// and the main-thread backtrace captured at the stall. Driven by
/// `HangDetectorRunner.shared`.
final class HangEventsViewController: BaseTableController {

    private let runner = HangDetectorRunner.shared

    private var refreshTimer: Timer?

    override init() {
        super.init()
        title = "Hang Events"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        tableView.backgroundColor = .black
        view.backgroundColor = .black
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HangEventCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .trash,
                target: self,
                action: #selector(handleClear)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(handleShare)
            )
        ]
    }

    // MARK: - DataSource

    override func numberOfSections(in _: UITableView) -> Int {
        1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        max(runner.events.count, 1)
    }

    override func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
        let count = runner.events.count
        let total = runner.events.reduce(0.0) { $0 + $1.duration }
        return "Hangs: \(count) · Total stall: \(String(format: "%.2f", total))s"
    }

    override func tableView(_: UITableView, titleForFooterInSection _: Int) -> String? {
        "Fires when the main thread stalls ≥ 0.25s past the 10s grace period."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HangEventCell", for: indexPath)
        cell.backgroundColor = .black
        cell.selectionStyle = .none

        let events = runner.events
        guard !events.isEmpty else {
            cell.textLabel?.text = "No hangs detected yet"
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.textAlignment = .center
            cell.detailTextLabel?.text = nil
            return cell
        }

        // Newest first.
        let event = events[events.count - 1 - indexPath.row]
        let topFrame = event.backtrace.first ?? "<no backtrace>"
        cell.textLabel?.text = "\(String(format: "%.2f", event.duration))s · \(event.timestamp.formatted())"
        cell.textLabel?.textColor = .systemRed
        cell.textLabel?.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.text = topFrame
        cell.detailTextLabel?.textColor = .lightGray
        cell.detailTextLabel?.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let events = runner.events
        guard !events.isEmpty else { return }
        let event = events[events.count - 1 - indexPath.row]
        let detail = HangDetailViewController(event: event)
        navigationController?.pushViewController(detail, animated: true)
    }

    // MARK: - Actions

    @objc private func handleClear() {
        guard !runner.events.isEmpty else { return }
        let alert = UIAlertController(
            title: "Clear Hangs",
            message: "Remove all \(runner.events.count) recorded hang events?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.runner.clearEvents()
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleShare() {
        let events = runner.events
        guard !events.isEmpty else {
            let alert = UIAlertController(
                title: "Nothing to share",
                message: "No hang events have been recorded yet.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let report = events.reversed().enumerated().map { index, event in
            let frames = event.backtrace.enumerated()
                .map { idx, frame in "  \(idx): \(frame)" }
                .joined(separator: "\n")
            let header = "#\(index + 1)\t\(event.timestamp.formatted())\t"
                + "\(String(format: "%.2f", event.duration))s"
            return "\(header)\n\(frames)"
        }.joined(separator: "\n\n")
        FileSharingManager.generateFileAndShare(text: report, fileName: "hang_events")
    }
}

// MARK: - Hang Detail

/// Shows the full backtrace for one hang event.
final class HangDetailViewController: BaseTableController {
    private let event: HangEvent

    init(event: HangEvent) {
        self.event = event
        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hang · \(String(format: "%.2f", event.duration))s"
        tableView.backgroundColor = .black
        view.backgroundColor = .black
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "doc.on.doc"),
                style: .plain,
                target: self,
                action: #selector(handleCopy)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(handleShare)
            )
        ]
    }

    private func reportText() -> String {
        let header = "Hang · \(String(format: "%.2f", event.duration))s · "
            + event.timestamp.formatted()
        let frames = event.backtrace.enumerated()
            .map { idx, frame in "\(idx): \(frame)" }
            .joined(separator: "\n")
        return "\(header)\n\n\(frames)"
    }

    @objc private func handleCopy() {
        UIPasteboard.general.string = reportText()
        let toast = UIAlertController(title: nil, message: "Backtrace copied", preferredStyle: .alert)
        present(toast, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            toast.dismiss(animated: true)
        }
    }

    @objc private func handleShare() {
        FileSharingManager.generateFileAndShare(
            text: reportText(),
            fileName: "hang_backtrace"
        )
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        max(event.backtrace.count, 1)
    }

    override func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
        "Backtrace · \(event.timestamp.formatted())"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FrameCell") ?? UITableViewCell(
            style: .default, reuseIdentifier: "FrameCell"
        )
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        if event.backtrace.isEmpty {
            cell.textLabel?.text = "<no backtrace captured>"
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.textAlignment = .center
        } else {
            cell.textLabel?.text = "\(indexPath.row): \(event.backtrace[indexPath.row])"
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            cell.textLabel?.numberOfLines = 0
        }
        return cell
    }
}
