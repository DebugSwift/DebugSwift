//
//  FrameDropTimelineViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois (Frame Drop Timeline) on 17/07/26.
//

import UIKit

/// Lists recorded frame-drop events (newest first) with a live FPS summary
/// header, plus Clear and Share actions. Driven by `FrameDropAdapter.shared`.
final class FrameDropTimelineViewController: BaseTableController {

    private let adapter = FrameDropAdapter.shared

    /// Refresh cadence for the live summary header while the view is on screen.
    private var refreshTimer: Timer?

    // MARK: - Lifecycle

    override init() {
        super.init()
        title = "Frame Drop Timeline"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        tableView.backgroundColor = .black
        view.backgroundColor = .black
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "FrameDropEventCell"
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
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
        max(adapter.timeline.events.count, 1)
    }

    override func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
        let count = adapter.timeline.events.count
        let current = adapter.currentFPS.map { String(format: "%.0f fps", $0) } ?? "—"
        return "Drops: \(count) · Current: \(current)"
    }

    override func tableView(_: UITableView, titleForFooterInSection _: Int) -> String? {
        "Threshold: below \(Int(adapter.timeline.dropThreshold)) fps · "
            + "Samples every \(adapter.timeline.sampleEveryN)th drop"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "FrameDropEventCell",
            for: indexPath
        )
        cell.backgroundColor = .black
        cell.selectionStyle = .none

        let events = adapter.timeline.events
        guard !events.isEmpty else {
            cell.textLabel?.text = "No drops recorded yet"
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.textAlignment = .center
            cell.detailTextLabel?.text = nil
            return cell
        }

        // Newest first.
        let event = events[events.count - 1 - indexPath.row]
        cell.textLabel?.text = "\(String(format: "%.1f", event.fps)) fps"
        cell.textLabel?.textColor = fpsColor(event.fps)
        cell.textLabel?.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        cell.detailTextLabel?.text = event.timestamp.formatted()
        cell.detailTextLabel?.textColor = .lightGray
        cell.detailTextLabel?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        return cell
    }

    // MARK: - Actions

    @objc private func handleClear() {
        guard !adapter.timeline.events.isEmpty else { return }
        let alert = UIAlertController(
            title: "Clear Timeline",
            message: "Remove all \(adapter.timeline.events.count) recorded frame drop events?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.adapter.timeline.clear()
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleShare() {
        let events = adapter.timeline.events
        guard !events.isEmpty else {
            let alert = UIAlertController(
                title: "Nothing to share",
                message: "No frame drop events have been recorded yet.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let report = events.reversed().enumerated().map { index, event in
            let ctx = event.context.map { " · \($0)" } ?? ""
            return "#\(index + 1)\t\(event.timestamp.formatted())\t\(String(format: "%.1f", event.fps)) fps\(ctx)"
        }.joined(separator: "\n")
        FileSharingManager.generateFileAndShare(text: report, fileName: "frame_drop_timeline")
    }

    // MARK: - Helpers

    private func fpsColor(_ fps: Double) -> UIColor {
        let threshold = adapter.timeline.dropThreshold
        if fps < threshold * 0.5 { return .systemRed }
        if fps < threshold * 0.8 { return .systemOrange }
        return .systemYellow
    }
}
