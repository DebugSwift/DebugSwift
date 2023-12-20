//
//  CrashViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import UIKit

final class CrashViewController: BaseController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray

        return tableView
    }()

    private let viewModel = CrashViewModel()

    override init() {
        super.init()
        setupTabBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }

    func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: .cell
        )

        tableView.register(
            MenuSwitchTableViewCell.self,
            forCellReuseIdentifier: MenuSwitchTableViewCell.identifier
        )

        view.backgroundColor = .black
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupTabBar() {
        title = "actions-crash".localized()
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "square.grid.2x2"),
            tag: 3
        )

        guard viewModel.numberOfItems() != .zero else { return }
        addRightBarButton(
            image: .init(named: "trash.circle"),
            tintColor: .red
        ) { [weak self] in
            self?.showAlert(
                with: "delete.title".localized(),
                title: "delete.subtitle".localized(),
                leftButtonTitle: "delete.action".localized(),
                leftButtonStyle: .destructive,
                leftButtonHandler: { _ in
                    self?.viewModel.handleClearAction()
                    self?.tableView.reloadData()
                },
                rightButtonTitle: "delete.cancel".localized(),
                rightButtonStyle: .cancel
            )
        }
    }
}

extension CrashViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        Features.allCases.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems()
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let feature = Features(rawValue: indexPath.section)

        switch feature {
        case .crashes:
            let data = viewModel.dataSourceForItem(atIndex: indexPath.row)
            let cell = tableView.dequeueReusableCell(
                withIdentifier: .cell,
                for: indexPath
            )
            cell.setup(title: data.title, subtitle: data.value)
            return cell
        default:
            return .init()
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 && viewModel.numberOfItems() != 0 ? "Crashes" : nil
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controller: UIViewController?
        switch Features(rawValue: indexPath.section) {
        case .crashes:
            let data = viewModel.data[indexPath.row]
            let viewModel = CrashDetailViewModel(data: data)
            controller = CrashDetailViewController(viewModel: viewModel)
        default:
            break
        }
        if let controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension CrashViewController {
    enum Features: Int, CaseIterable {
        case crashes
    }
}
