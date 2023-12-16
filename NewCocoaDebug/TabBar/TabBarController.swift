import UIKit

class BaseController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    init(withNib: Bool) {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BaseTableController: UITableViewController {
    init() {
        super.init(style: .grouped)
        configureAppearance()
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
        configureAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureAppearance() {
        UINavigationBar.appearance().barTintColor = .black
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().backgroundColor = .clear
        UITabBar.appearance().barTintColor = .black
    }
}

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBar()
        configureNavigation()
    }
}

// MARK: - Private Extensions

fileprivate extension TabBarController {

    func configureTabBar() {
        let controllers: [UIViewController] = [
            InterfaceViewController(),
            NetworkViewController(),
            PerformanceViewController(),
            ResourcesViewController(),
            AppViewController()
        ]

        viewControllers = controllers.map {
            UINavigationController(rootViewController: $0)
        }

        tabBar.tintColor = .white
        tabBar.backgroundColor = .black
        tabBar.unselectedItemTintColor = .gray
    }

    func configureNavigation() {
        // Remove the default back button
        navigationItem.hidesBackButton = true

        let closeButton: UIBarButtonItem

        if #available(iOS 14.0, *) {
            closeButton = UIBarButtonItem(systemItem: .close)
            closeButton.target = self
            closeButton.action = #selector(closeButtonTapped)
        } else {
            closeButton = UIBarButtonItem(
                title: "Close",
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )
        }

        navigationItem.rightBarButtonItem = closeButton
    }

    @objc func closeButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
