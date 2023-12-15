import UIKit

class BaseController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    init(withNib: Bool) {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            NetworkViewController(),
            PerformanceViewController(),
            ResourcesViewController(),
            InterfaceViewController(),
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
        configureAppearance()
    }

    func configureAppearance() {
        UINavigationBar.appearance().barTintColor = .black
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().backgroundColor = .clear
        UITabBar.appearance().barTintColor = .black
    }

    @objc func closeButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
