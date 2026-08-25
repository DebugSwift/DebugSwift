//
//  BacktraceEventsViewController.swift
//  DebugSwift
//
//  Inspector UI for programmatically captured backtraces.
//  Two-level pattern: list of captures → frame detail.
//  Follows HangEventsViewController / HangDetailViewController.
//

import UIKit

// MARK: - List

/// Lists programmatically captured backtraces (newest first).  Tap a row to
/// see the full frame list.  Driven by ``BacktraceManager``.
final class BacktraceEventsViewController: BaseTableController {

    private let manager = BacktraceManager.shared

    private var refreshTimer: Timer?

    override init() {
        super.init()
        title = "Backtraces"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        tableView.backgroundColor = .black
        view.backgroundColor = .black
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BacktraceEventCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tableView.reloadData() }
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
        max(manager.backtraces.count, 1)
    }

    override func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
        let count = manager.backtraces.count
        return "Captures: \(count)"
    }

    override func tableView(_: UITableView, titleForFooterInSection _: Int) -> String? {
        "Programmatic backtraces captured via DebugSwift.Performance.Backtrace.capture()"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BacktraceEventCell", for: indexPath)
        cell.backgroundColor = .black
        cell.selectionStyle = .none

        let backtraces = manager.backtraces
        guard !backtraces.isEmpty else {
            cell.textLabel?.text = "No backtraces captured yet"
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.textAlignment = .center
            cell.detailTextLabel?.text = nil
            return cell
        }

        let bt = backtraces[indexPath.row] // already newest first
        let topFrame = bt.frames.first?.symbol ?? "<no frames>"
        let labelPart = bt.label.map { "\($0) · " } ?? ""
        cell.textLabel?.text = "\(labelPart)\(bt.timestamp.formatted())"
        cell.textLabel?.textColor = .systemTeal
        cell.textLabel?.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.text = topFrame
        cell.detailTextLabel?.textColor = .lightGray
        cell.detailTextLabel?.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let backtraces = manager.backtraces
        guard !backtraces.isEmpty, indexPath.row < backtraces.count else { return }
        let detail = BacktraceDetailViewController(backtrace: backtraces[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }

    // MARK: - Actions

    @objc private func handleClear() {
        let alert = UIAlertController(
            title: "Clear All Backtraces?",
            message: "This will remove all \(manager.backtraces.count) captured backtrace(s).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.manager.clear()
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleShare() {
        let text = manager.backtraces.map { bt -> String in
            let header = "\(bt.label.map { "\($0) · " } ?? "")\(bt.timestamp.formatted())"
            let frames = bt.frames.enumerated()
                .map { idx, frame in "\(idx): \(frame.symbol)" }
                .joined(separator: "\n")
            return "\(header)\n\(frames)"
        }.joined(separator: "\n\n---\n\n")

        guard !text.isEmpty else {
            let alert = UIAlertController(
                title: nil, message: "No backtraces to share", preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        FileSharingManager.generateFileAndShare(text: text, fileName: "backtraces")
    }
}

// MARK: - Detail

/// Shows the full frame list for one captured backtrace.
final class BacktraceDetailViewController: BaseTableController {
    private let backtrace: CapturedBacktrace

    init(backtrace: CapturedBacktrace) {
        self.backtrace = backtrace
        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = backtrace.label ?? "Backtrace"
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
        let header = "\(backtrace.label.map { "\($0) · " } ?? "")\(backtrace.timestamp.formatted())"
        let frames = backtrace.frames.enumerated()
            .map { idx, frame in "\(idx): \(frame.symbol)" }
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
            fileName: "backtrace"
        )
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        max(backtrace.frames.count, 1)
    }

    override func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
        "Backtrace · \(backtrace.timestamp.formatted())"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FrameCell") ?? UITableViewCell(
            style: .default, reuseIdentifier: "FrameCell"
        )
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        if backtrace.frames.isEmpty {
            cell.textLabel?.text = "<no frames captured>"
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.textAlignment = .center
        } else {
            cell.textLabel?.text = "\(indexPath.row): \(backtrace.frames[indexPath.row].symbol)"
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            cell.textLabel?.numberOfLines = 0
        }
        return cell
    }
}
