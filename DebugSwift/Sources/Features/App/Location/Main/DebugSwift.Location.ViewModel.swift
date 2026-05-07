//
//  Location.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import CoreLocation
import Foundation

final class LocationViewModel: NSObject {
    var selectedIndex: Int = LocationToolkit.shared.indexSaved

    var numberOfRows: Int {
        LocationToolkit.shared.presetLocations.count + 1
    }

    var locations: [PresetLocation] {
        LocationToolkit.shared.presetLocations
    }

    var customDescription: String? {
        guard customSelected else { return nil }
        return coordinateString(with: LocationToolkit.shared.simulatedLocation)
    }

    var customSelected: Bool {
        guard LocationToolkit.shared.simulatedLocation != nil else { return false }
        return LocationToolkit.shared.indexSaved == -1
    }

    func resetLocation() {
        LocationToolkit.shared.simulatedLocation = nil
        selectedIndex = -1
    }

    func coordinateString(with location: CLLocation?) -> String {
        guard let coordinate = location?.coordinate else { return "" }
        let latitudeDegreesMinutesSeconds = degreesMinutesSeconds(with: coordinate.latitude)
        let latitudeDirectionLetter = coordinate.latitude >= 0 ? "N" : "S"

        let longitudeDegreesMinutesSeconds = degreesMinutesSeconds(with: coordinate.longitude)
        let longitudeDirectionLetter = coordinate.longitude >= 0 ? "E" : "W"

        return String(format: "%@%@, %@%@", latitudeDegreesMinutesSeconds, latitudeDirectionLetter, longitudeDegreesMinutesSeconds, longitudeDirectionLetter)
    }

    func degreesMinutesSeconds(with coordinate: CLLocationDegrees) -> String {
        let seconds = Int(coordinate * 3600)
        let degrees = seconds / 3600
        var remainingSeconds = abs(seconds % 3600)
        let minutes = remainingSeconds / 60
        remainingSeconds %= 60
        return String(format: "%d°%d'%d\"", abs(degrees), minutes, remainingSeconds)
    }
}
