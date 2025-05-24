//
//  MapView.swift
//  Example
//
//  Created by Matheus Gois on 12/06/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView_13: UIViewControllerRepresentable {
    @Binding var userTrackingMode: MKUserTrackingMode

    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView_13
        var locationManager = CLLocationManager()
        weak var mapView: MKMapView?

        init(_ parent: MapView_13) {
            self.parent = parent
            super.init()
            self.locationManager.delegate = self
            self.locationManager.requestWhenInUseAuthorization()
        }

        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                break
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            @unknown default:
                fatalError("Unhandled case for location authorization status")
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            print("""
            -----
            NEW LOCATION IS UPDATED, TO SHOW IN MAP, NEEDS RESTART THE APP

            \(locations)

            -----
            """)
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            self.mapView = mapView
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = userTrackingMode
        mapView.frame = viewController.view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        viewController.view.addSubview(mapView)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let mapView = uiViewController.view.subviews.first as? MKMapView {
            mapView.userTrackingMode = userTrackingMode
        }
    }
}
