//
//  Performance.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class NetworkViewController: BaseController, UISearchBarDelegate {

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        return tableView
    }()

    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search"
        return searchBar
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
        navigationController?.navigationBar.prefersLargeTitles = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.mockRequest()
            self.mockRequest()
            self.mockRequest()
            self.mockRequest()
            self.mockRequest()
        }
    }

    func setup() {
        title = "Network"
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(
                title: "Network",
                image: UIImage(systemName: "network"),
                tag: 0
            )
        } else {
            // Fallback on earlier versions
        }

        NetworkHelper.shared.enable()
        setupKeyboardDismissGesture()
        observers()
    }

    func observers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "reloadHttp_CocoaDebug"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadHttp(needScrollToEnd: self?.viewModel.reachEnd ?? true)
        }
    }

    func reloadHttp(needScrollToEnd: Bool = false) {
        guard viewModel.reloadDataFinish else { return }

        viewModel.applyFilter()
        tableView.reloadData()
    }

    func setupSearchBar() {
        searchBar.delegate = self
        navigationItem.titleView = searchBar
    }

    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.networkSearchWord = searchText
        viewModel.applyFilter()
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        viewModel.applyFilter()
        tableView.reloadData()
    }

    private func mockRequest() {
        // Replace this URL with the actual endpoint you want to request
        let url = URL(string: "https://reqres.in/api/users?page=2")!

        // Create a URLSession object
        let session = URLSession.shared

        // Create a data task
        let task = session.dataTask(with: url) { (data, _, error) in
            // Check for errors
            if let error = error {
                print("Error: \(error)")
                return
            }

            // Check if data is available
            guard let data = data else {
                print("No data received")
                return
            }

            do {
                // Parse the JSON data
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("JSON Response: \(json)")
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }

        // Start the task
        task.resume()
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
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NetworkCell", for: indexPath
        ) as! NetworkTableViewCell
        cell.setup(viewModel.models[indexPath.row])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.models[indexPath.row]
        let controller = NetworkViewControllerDetail(model: model)
        navigationController?.pushViewController(controller, animated: true)
    }
}
