//
//  Network.Controller.Detail.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

final class NetworkViewControllerDetail: BaseController {
    private var model: HttpModel
    private var infos: [Config]
    private var filteredInfos: [Config] = []
    private var searchIndex: Int = .zero {
        didSet {
            customBackButton.isEnabled = searchIndex == .zero
            customForwardButton.isEnabled = true
        }
    }

    private var numberFounded: Int {
        let searchText = searchController.searchBar.text ?? ""
        return _infos.filter { info in
            info.description.range(of: searchText, options: .caseInsensitive) != nil
        }.count
    }

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = Theme.shared.backgroundColor

        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        return searchController
    }()

    private lazy var customBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.named("chevron.left", default: "←"), for: .normal)
        button.tintColor = .white
        button.isEnabled = false
        button.addTarget(self, action: #selector(customBackButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var customForwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.named("chevron.right", default: "→"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(customForwardButtonTapped), for: .touchUpInside)
        return button
    }()

    init(model: HttpModel) {
        self.model = model
        self.infos = .init(model: model)
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupNavigation()
        setupSearchNav(hide: true)
        setupSearch()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setupSearchNav(hide: true)
    }

    private func setupNavigation() {
        addRightBarButton(
            actions: [
                .init(
                    image: .named("doc.on.doc", default: "copy".localized()),
                    completion: { [weak self] in
                        self?.copyButtonTapped()
                    }
                ),
                .init(
                    image: .named("ellipsis.curlybraces", default: "Curl"),
                    completion: { [weak self] in
                        self?.copyCurlButtonTapped()
                    }
                ),
                .init(
                    image: .named("square.and.arrow.up", default: "share".localized()),
                    completion: { [weak self] in
                        self?.shareButtonTapped()
                    }
                )
            ]
        )
    }

    private func setupSearchNav(hide: Bool) {
        let customBackButtonItem = UIBarButtonItem(customView: customBackButton)
        let customForwardButtonItem = UIBarButtonItem(customView: customForwardButton)
        tabBarController?.navigationItem.leftBarButtonItems = hide ? [] : [customBackButtonItem, customForwardButtonItem]
    }

    private func setup() {
        title = "network-details-title".localized()
    }

    private func setupSearch() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    @objc private func customBackButtonTapped() {
        searchIndex -= 1
    }

    @objc private func customForwardButtonTapped() {
        searchIndex += 1
    }
}

extension NetworkViewControllerDetail: UITableViewDelegate, UITableViewDataSource {
    private var _infos: [Config] {
        searchController.isActive ? filteredInfos : infos
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            NetworkTableViewCell.self,
            forCellReuseIdentifier: "NetworkCell"
        )
        tableView.register(
            NetworkTableViewCellDetail.self,
            forCellReuseIdentifier: "NetworkCellDetail"
        )
        view.backgroundColor = Theme.shared.backgroundColor

        // Configure constraints for the tableView
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        _infos.count + 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == .zero ? .zero : UITableView.automaticDimension
    }

    func tableView(
        _: UITableView, viewForHeaderInSection section: Int
    ) -> UIView? {
        if section == .zero {
            return nil
        } else {
            let label = UILabel()
            label.backgroundColor = Theme.shared.backgroundColor

            label.text = "    \(_infos[section - 1].title)"
            label.textColor = .gray
            label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            return label
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == .zero {
            let cell =
                tableView.dequeueReusableCell(
                    withIdentifier: "NetworkCell",
                    for: indexPath
                ) as! NetworkTableViewCell
            cell.setup(model)

            return cell
        } else {
            let cell =
                tableView.dequeueReusableCell(
                    withIdentifier: "NetworkCellDetail",
                    for: indexPath
                ) as! NetworkTableViewCellDetail

            cell.setup(_infos[indexPath.section - 1].description, searchController.searchBar.text, searchIndex)

            return cell
        }
    }
}

extension NetworkViewControllerDetail: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }

        filteredInfos =
            searchText.isEmpty
                ? infos
                : infos.filter { $0.description.localizedCaseInsensitiveContains(searchText) }

        setupSearchNav(hide: searchText.isEmpty)

        print("Encontrados: \(numberFounded)")

        tableView.reloadData()
    }
}

// MARK: - Config

extension NetworkViewControllerDetail {
    struct Config {
        let title: String
        let description: String
    }
}

extension [NetworkViewControllerDetail.Config] {
    init(model: HttpModel) {
        self = [
            .init(
                title: "TOTAL TIME",
                description: model.totalDuration ?? "No data"
            ),
            .init(
                title: "REQUEST HEADER",
                description: model.requestHeaderFields?.formattedString() ?? "No data"
            ),
            .init(
                title: "REQUEST",
                description: model.requestData?.formattedString() ?? "No data"
            ),
            .init(
                title: "RESPONSE HEADER",
                description: model.responseHeaderFields?.formattedString() ?? "No data"
            ),
            .init(
                title: "RESPONSE",
                description: model.responseData?.formattedString() ?? "No data"
            ),
            .init(
                title: "RESPONSE SIZE",
                description: model.responseData?.formattedSize() ?? "No data"
            ),
            .init(
                title: "MIME TYPE",
                description: model.mineType ?? "No data"
            )
        ]
    }
}

extension NetworkViewControllerDetail {
    @objc private func copyButtonTapped() {
        UIPasteboard.general.string = formatLog(model: model)
    }

    @objc private func shareButtonTapped() {
        let logText = formatLog(model: model)

        var fileName = model.url?.path.replacingOccurrences(of: "/", with: "-") ?? "-log"
        fileName.removeFirst()

        let tempURL = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent("\(fileName).txt")

        do {
            try logText.write(to: tempURL, atomically: true, encoding: .utf8)

            let activity = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            if let popover = activity.popoverPresentationController {
                popover.sourceView = view
                popover.permittedArrowDirections = .up
            }
            present(activity, animated: true, completion: nil)
        } catch {
            Debug.print("Error: \(error.localizedDescription)")
        }
    }

    @objc private func copyCurlButtonTapped() {
        let curlCommand = """
            curl -X \(model.method ?? "") \\
                 -H "\(model.requestHeaderFields?.formattedCurlString() ?? "")" \\
                 -d "\(model.requestData?.formattedCurlString() ?? "")" \\
                 \(model.url?.absoluteString ?? "")
        """
        UIPasteboard.general.string = curlCommand
    }

    private func formatLog(
        model: HttpModel
    ) -> String {
        let formattedLog = """
        [\(model.method ?? "")] \(model.startTime ?? "") (\(model.statusCode ?? ""))

        ------- URL -------
        \(model.url?.absoluteString ?? "No data")

        ------- REQUEST HEADER -------
        \(model.requestHeaderFields?.formattedString() ?? "No data")

        ------- REQUEST -------
        \(model.requestData?.formattedString() ?? "No data")

        ------- RESPONSE HEADER -------
        \(model.responseHeaderFields?.formattedString() ?? "No data")

        ------- RESPONSE -------
        \(model.responseData?.formattedString() ?? "No data")

        ------- RESPONSE SIZE -------
        \(model.responseData?.formattedSize() ?? "No data")

        ------- TOTAL TIME -------
        \(model.totalDuration ?? "No data")

        ------- MIME TYPE -------
        \(model.mineType ?? "No data")
        """
        return formattedLog
    }
}
