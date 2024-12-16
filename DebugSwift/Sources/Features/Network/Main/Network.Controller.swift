//
//  Network.Controller.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class NetworkViewController: BaseController, MainFeatureType {
    var controllerType: DebugSwiftFeature { .network }

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = Theme.shared.backgroundColor
        tableView.estimatedRowHeight = 80
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "search".localized()
        return searchController
    }()

    private let viewModel = NetworkViewModel()

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        addDeleteButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewModel.firstIn {
            scrollToBottom()
            viewModel.firstIn = false
        }
    }

    func setup() {
        title = "network-title".localized()
        tabBarItem = UITabBarItem(
            title: title,
            image: .named("network"),
            tag: 0
        )
        view.backgroundColor = Theme.shared.backgroundColor
        setupKeyboardDismissGesture()
        observers()
    }

    func observers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "reloadHttp_DebugSwift"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let success = notification.object as? Bool {
                self?.reloadHttp(
                    needScrollToEnd: self?.viewModel.reachEnd ?? true,
                    success: success
                )
            }
        }
    }

    func reloadHttp(needScrollToEnd: Bool = false, success: Bool = true) {
        guard viewModel.reloadDataFinish else { return }

        FloatViewManager.animate(success: success)
        viewModel.applyFilter()
        tableView.reloadData()

        if needScrollToEnd {
            scrollToBottom()
        }
    }

    private func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func scrollToBottom() {
        if tableView.numberOfSections > 0 {
            let lastSection = tableView.numberOfSections - 1
            let lastRow = tableView.numberOfRows(inSection: lastSection) - 1

            if lastRow >= 0 {
                let indexPath = IndexPath(row: lastRow, section: lastSection)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }

    private func addDeleteButton() {
        guard !viewModel.models.isEmpty else { return }
        addRightBarButton(
            image: .named("trash.circle", default: "clean".localized()),
            tintColor: .red
        ) { [weak self] in
            self?.showAlert(
                with: "delete.title".localized(),
                title: "delete.subtitle".localized(),
                leftButtonTitle: "delete.action".localized(),
                leftButtonStyle: .destructive,
                leftButtonHandler: { _ in
                    self?.clearAction()
                },
                rightButtonTitle: "delete.cancel".localized(),
                rightButtonStyle: .cancel
            )
        }
    }

    private func clearAction() {
        viewModel.handleClearAction()
        tableView.reloadData()
    }
}

extension NetworkViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.networkSearchWord = searchText
        viewModel.applyFilter()
        tableView.reloadData()
    }
}

extension NetworkViewController: UITableViewDelegate, UITableViewDataSource {
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            NetworkTableViewCell.self,
            forCellReuseIdentifier: "NetworkCell"
        )

        // Configure constraints for the tableView
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NetworkCell",
            for: indexPath
        ) as! NetworkTableViewCell
        cell.setup(viewModel.models[indexPath.row])

        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.models[indexPath.row]
        let controller = NetworkViewControllerDetail(model: model)
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "") { [weak self] _, _, _ in
            guard let self else { return }

            if let url = self.viewModel.models[indexPath.row].url {
                UIPasteboard.general.string = url.absoluteString

                self.showAlert(
                    with: "alert.url.copied.description".localized(),
                    title: "alert.url.copied.title".localized()
                )
            }
        }

        action.image = .named("doc.on.doc", default: "copy".localized())
        action.backgroundColor = .gray

        return UISwipeActionsConfiguration(actions: [action])
    }
}
