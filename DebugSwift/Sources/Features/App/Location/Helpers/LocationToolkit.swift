//
//  LocationToolkit.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import CoreLocation
import Foundation

final class LocationToolkit {

    static let shared = LocationToolkit()

    var simulatedLocation: CLLocation? {
        get {
            let latitude = UserDefaults.standard.double(forKey: Constants.simulatedLatitude)
            let longitude = UserDefaults.standard.double(forKey: Constants.simulatedLongitude)
            guard !latitude.isZero, !longitude.isZero else { return nil }

            return .init(latitude: latitude, longitude: longitude)
        }
        set {
            if let location = newValue {
                UserDefaults.standard.set(
                    location.coordinate.latitude,
                    forKey: Constants.simulatedLatitude
                )
                UserDefaults.standard.set(
                    location.coordinate.longitude,
                    forKey: Constants.simulatedLongitude
                )
            } else {
                UserDefaults.standard.removeObject(
                    forKey: Constants.simulatedLatitude
                )
                UserDefaults.standard.removeObject(
                    forKey: Constants.simulatedLongitude
                )
            }
            UserDefaults.standard.synchronize()

            CLLocationManagerTracker.triggerUpdateForAllLocations()
        }
    }

    var indexSaved: Int {
        guard let simulatedLocation else { return -1 }
        if let index = presetLocations.firstIndex(
            where: {
                $0.latitude == simulatedLocation.coordinate.latitude &&
                    $0.longitude == simulatedLocation.coordinate.longitude
            }
        ) {
            return index + 1
        }

        return -1
    }

    let presetLocations: [PresetLocation] = {
        var presetLocations = [PresetLocation]()
        presetLocations.append(
            PresetLocation(
                title: "Алматы",
                latitude: 43.229784712718995,
                longitude: 76.93310379690176
            )
        )
        presetLocations.append(
            PresetLocation(
                title: "Омск",
                latitude: 54.994700483953146,
                longitude: 73.36670406191908
            )
        )
        presetLocations.append(
            PresetLocation(
                title: "Краснодар",
                latitude: 45.04692035288898,
                longitude: 39.032586261767655
            )
        )

        return presetLocations
    }()
}

final class PresetLocation {
    var title: String
    var latitude: Double
    var longitude: Double

    init(title: String, latitude: Double, longitude: Double) {
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension LocationToolkit {
    enum Constants {
        static let simulatedLatitude = "_simulatedLocationLatitude"
        static let simulatedLongitude = "_simulatedLocationLongitude"
    }
}
