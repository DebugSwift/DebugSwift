//
//  ObjectExplorer.Controller.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025.
//

import UIKit

final class ObjectExplorerViewController: BaseController, MainFeatureType {
    var controllerType: DebugSwiftFeature { .objectExplorer }

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray
        return tableView
    }()

    private var items: [ExplorerItem] = []

    override init() {
        super.init()
        setupTabBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        buildItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildItems()
        tableView.reloadData()
    }

    private func setupTabBar() {
        title = "Explorer"
        tabBarItem = UITabBarItem(
            title: title,
            image: .named("magnifyingglass.circle", default: "🔍"),
            tag: 5
        )
    }

    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: .cell
        )

        view.backgroundColor = UIColor.black
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func buildItems() {
        var result: [ExplorerItem] = []

        // Key Window
        result.append(ExplorerItem(
            title: "Key Window",
            subtitle: "Inspect the app's key window",
            objectProvider: {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows)
                    .first(where: \.isKeyWindow)
            }
        ))

        // Root View Controller
        result.append(ExplorerItem(
            title: "Root View Controller",
            subtitle: "Inspect the root view controller",
            objectProvider: {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows)
                    .first(where: \.isKeyWindow)?
                    .rootViewController
            }
        ))

        // Top View Controller
        result.append(ExplorerItem(
            title: "Top View Controller",
            subtitle: "Inspect the topmost presented controller",
            objectProvider: {
                Self.topViewController()
            }
        ))

        // UIApplication
        result.append(ExplorerItem(
            title: "UIApplication.shared",
            subtitle: "Inspect the shared application instance",
            objectProvider: {
                UIApplication.shared
            }
        ))

        // UIScreen
        result.append(ExplorerItem(
            title: "UIScreen.main",
            subtitle: "Inspect the main screen",
            objectProvider: {
                UIScreen.main
            }
        ))

        // UserDefaults
        result.append(ExplorerItem(
            title: "UserDefaults.standard",
            subtitle: "Inspect standard user defaults",
            objectProvider: {
                UserDefaults.standard
            }
        ))

        // FileManager
        result.append(ExplorerItem(
            title: "FileManager.default",
            subtitle: "Inspect the default file manager",
            objectProvider: {
                Foundation.FileManager.default
            }
        ))

        // NotificationCenter
        result.append(ExplorerItem(
            title: "NotificationCenter.default",
            subtitle: "Inspect the default notification center",
            objectProvider: {
                NotificationCenter.default
            }
        ))

        // Bundle.main
        result.append(ExplorerItem(
            title: "Bundle.main",
            subtitle: "Inspect the main bundle",
            objectProvider: {
                Bundle.main
            }
        ))

        // Custom registered objects
        for entry in ObjectExplorerRegistry.shared.entries {
            result.append(ExplorerItem(
                title: entry.name,
                subtitle: "Custom registered object",
                objectProvider: entry.objectProvider
            ))
        }

        items = result
    }

    private static func topViewController(
        from controller: UIViewController? = nil
    ) -> UIViewController? {
        let root = controller ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ObjectExplorerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        let item = items[indexPath.row]
        cell.setup(
            title: item.title,
            subtitle: item.subtitle
        )
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        guard let object = item.objectProvider() else {
            let alert = UIAlertController(
                title: "Object Unavailable",
                message: "The object is nil or no longer available.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let detail = ObjectExplorerDetailViewController(
            object: object,
            title: item.title
        )
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - Explorer Item Model

extension ObjectExplorerViewController {
    struct ExplorerItem {
        let title: String
        let subtitle: String
        let objectProvider: @MainActor () -> Any?
    }
}
