//
//  DocRecorderPanelController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import UIKit

final class DocRecorderPanelController: BaseController {
    private let storage = RecordingSessionStorage.shared
    private var savedRecordings: [SavedRecording] = []

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        return tableView
    }()

    private let emptyStateView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true

        let imageView = UIImageView(image: UIImage(systemName: "record.circle"))
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "No Recordings Yet"
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = .gray
        titleLabel.textAlignment = .center

        let descLabel = UILabel()
        descLabel.text = "Tap Start to record app interactions\nwith annotated screenshots"
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .gray
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, descLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32),
        ])

        return container
    }()

    override init() {
        super.init()
        title = "Doc Recorder"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavBar()
        loadRecordings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecordings()
    }

    private func setupNavBar() {
        let startButton = UIBarButtonItem(
            title: "● Record",
            style: .plain,
            target: self,
            action: #selector(startRecording)
        )
        startButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = startButton
    }

    private func setupUI() {
        view.backgroundColor = .black

        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadRecordings() {
        savedRecordings = storage.loadAllRecordings()
        tableView.reloadData()
        emptyStateView.isHidden = !savedRecordings.isEmpty
    }

    @objc private func startRecording() {
        WindowManager.removeDebugger()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            DocRecorderOverlayManager.shared.show()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension DocRecorderPanelController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        savedRecordings.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "RecordingCell")
        let recording = savedRecordings[indexPath.row]

        cell.textLabel?.text = recording.title
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.text = "\(recording.imageCount) images"
        cell.detailTextLabel?.textColor = .gray
        cell.imageView?.image = UIImage(systemName: "record.circle")
        cell.imageView?.tintColor = .systemRed
        cell.backgroundColor = .black
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        64.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = savedRecordings[indexPath.row]
        let detailVC = DocRecorderDetailController(recording: recording)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(
        _: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completionHandler in
            guard let self else { return }
            let recording = self.savedRecordings[indexPath.row]
            self.storage.deleteRecording(recording)
            self.loadRecordings()
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
