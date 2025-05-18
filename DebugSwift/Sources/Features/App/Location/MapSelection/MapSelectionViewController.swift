//
//  MapSelectionViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import MapKit
import UIKit

protocol LocationSelectionDelegate: AnyObject {
    func didSelectLocation(_ location: CLLocation)
}

final class MapSelectionViewController: BaseController {
    private var mapView: MKMapView?

    private var selectedLocationAnnotation: MKPointAnnotation?
    private var selectedLocation: CLLocation?

    weak var delegate: LocationSelectionDelegate?

    init(
        selectedLocation: CLLocation? = nil,
        delegate: LocationSelectionDelegate? = nil
    ) {
        self.selectedLocation = selectedLocation
        self.delegate = delegate
        super.init()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
    }

    private func setup() {
        setupMapView()
        setupUI()
        setupNavigationBar()
        setupGestureRecognizer()
    }

    private func setupMapView() {
        mapView = MKMapView()

        if let initialLocation = selectedLocation {
            let initialCoordinate = initialLocation.coordinate
            let annotation = MKPointAnnotation()
            annotation.coordinate = initialCoordinate
            mapView?.addAnnotation(annotation)

            let region = MKCoordinateRegion(
                center: initialCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            )

            mapView?.setRegion(region, animated: true)
        }
    }

    private func setupUI() {
        title = "Select Location"
        view.backgroundColor = UIColor.black

        guard let mapView else { return }
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }

    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView?.addGestureRecognizer(tapGesture)
    }

    @objc private func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let mapView else { return }
        let locationInView = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)

        if let selectedLocationAnnotation {
            selectedLocationAnnotation.coordinate = coordinate
        } else {
            selectedLocationAnnotation = MKPointAnnotation()
            selectedLocationAnnotation?.coordinate = coordinate
            selectedLocationAnnotation.map { mapView.removeAnnotation($0) }
            mapView.addAnnotation(selectedLocationAnnotation!)
        }
    }

    @objc private func doneButtonTapped() {
        if let selectedLocationCoordinate = selectedLocationAnnotation?.coordinate {
            let selectedLocation = CLLocation(latitude: selectedLocationCoordinate.latitude, longitude: selectedLocationCoordinate.longitude)
            delegate?.didSelectLocation(selectedLocation)
        }
        navigationController?.popViewController(animated: true)
    }

    // Handle back button press
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            // If the user is navigating back, but not pressing "Done", remove the selected location annotation
            selectedLocationAnnotation.map { mapView?.removeAnnotation($0) }
        }
    }
}
