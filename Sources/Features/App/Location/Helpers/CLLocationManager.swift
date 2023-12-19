//
//  CLLocationManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation
import CoreLocation

extension CLLocationManager {
    static func swizzleMethods() {
        let originalSelector = #selector(CLLocationManager.startUpdatingLocation)
        let swizzledSelector = #selector(swizzledStartLocation)
        SwizzleManager.swizzle(
            CLLocationManager.self,
            originalSelector: originalSelector,
            swizzledSelector: swizzledSelector
        )

        let originalStopSelector = #selector(CLLocationManager.requestLocation)
        let swizzledRequestSelector = #selector(swizzedRequestLocation)
        SwizzleManager.swizzle(
            CLLocationManager.self,
            originalSelector: originalStopSelector,
            swizzledSelector: swizzledRequestSelector
        )
    }

    private var simulatedLocation: CLLocation? { LocationToolkit.shared.simulatedLocation }

    @objc func swizzledStartLocation() {}

    @objc func swizzedRequestLocation() {
        if let simulatedLocation = simulatedLocation {
            delegate?.locationManager?(self, didUpdateLocations: [simulatedLocation])
        } else {
            swizzedRequestLocation()
        }
    }
}
