//
//  LocationManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {

    static var shared = LocationManager()
    private var locationManager = CLLocationManager()

    var didUpdate: ((String) -> Void)?

    func requestLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()

        locationManager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if let error {
                    print("Error: " + error.localizedDescription)
                    return
                }

                if let placemark = placemarks?.first {
                    self.displayLocationInfo(placemark)
                } else {
                    print("Error with the data.")
                }
            }
        }
    }

    func displayLocationInfo(_ placemark: CLPlacemark) {
        locationManager.stopUpdatingLocation()

        let value = """
        \(placemark.locality ?? "")
        \(placemark.postalCode ?? "")
        \(placemark.administrativeArea ?? "")
        \(placemark.country ?? "")
        """

        didUpdate?(value)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: " + error.localizedDescription)
    }
}
