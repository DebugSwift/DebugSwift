//
//  LocationViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation
import UIKit
import CoreLocation

final class LocationViewController: BaseController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray

        return tableView
    }()

    private var resetButton: UIBarButtonItem? {
        navigationItem.rightBarButtonItem
    }

    private let viewModel = LocationViewModel()

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }

    func resetLocation() {
        viewModel.resetLocation()
        resetButton?.isEnabled = false
        tableView.reloadData()
    }

    func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: .cell
        )

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        addRightBarButton(
            image: .init(named: "clear"),
            tintColor: .red
        ) { [weak self] in
            self?.resetLocation()
        }
    }

    func setup() {
        title = "location-title".localized()
    }
}

extension LocationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: .cell,
            for: indexPath
        )
        let image = UIImage(named: "checkmark.circle")
        if indexPath.row == 0 {
            cell.setup(
                title: "custom".localized(),
                subtitle: viewModel.customDescription,
                image: viewModel.customSelected ? image : nil
            )
            return cell
        } else {
            let location = viewModel.locations[indexPath.row - 1]
            cell.setup(
                title: location.title,
                image: indexPath.row == viewModel.selectedIndex ? image : nil
            )
            return cell
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        80.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == .zero {
            let controller = MapSelectionViewController(
                selectedLocation: LocationToolkit.shared.simulatedLocation,
                delegate: self
            )
            navigationController?.pushViewController(controller, animated: true)
        } else {
            viewModel.selectedIndex = indexPath.row
            let location = viewModel.locations[indexPath.row - 1]
            LocationToolkit.shared.simulatedLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
            resetButton?.isEnabled = true
            tableView.reloadData()
        }
    }
}

extension LocationViewController: LocationSelectionDelegate {
    func didSelectLocation(_ location: CLLocation) {
        LocationToolkit.shared.simulatedLocation = location
        resetButton?.isEnabled = true
        viewModel.selectedIndex = .zero
        tableView.reloadData()
    }
}
