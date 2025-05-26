//
//  MapView.swift
//  Example
//
//  Created by Matheus Gois on 12/06/24.
//

import SwiftUI
import MapKit
import CoreLocation

@available(iOS 14.0, *)
struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )

    private var manager = MapViewManager()

    var body: some View {
        if #available(iOS 17.0, *) {
            MapView17(manager: manager)
        } else {
            Map(
                coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow)
            )
            .onAppear {
                manager.start()
            }
        }
    }
}

@available(iOS 17.0, *)
struct MapView17: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    var manager: MapViewManager

    var body: some View {
        Map(position: $position) {
            // MapContentBuilder content can be added here
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            manager.start()
        }
    }
}

@available(iOS 14.0, *)
class MapViewManager: NSObject, CLLocationManagerDelegate {
    @State private var locationManager = CLLocationManager()

    func start() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
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
}

@available(iOS 14.0, *)
extension MapViewManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        mapView.setRegion(region, animated: true)
    }
}
