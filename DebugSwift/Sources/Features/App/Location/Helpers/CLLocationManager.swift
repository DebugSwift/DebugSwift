//
//  CLLocationManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import CoreLocation
import Foundation

final class CLLocationManagerTracker {

    private static var managers: [CLLocationManager] = []

    static func add(manager: CLLocationManager) {
        managers.append(manager)
    }

    static func triggerUpdateForAllLocations() {
        for manager in managers {
            manager.requestLocation()
        }
    }
}

extension CLLocationManager {
    static func swizzleMethods() {
        SwizzleManager.swizzle(
            CLLocationManager.self,
            originalSelector: #selector(CLLocationManager.init),
            swizzledSelector: #selector(swizzledInit)
        )

        SwizzleManager.swizzle(
            CLLocationManager.self,
            originalSelector: #selector(locationServicesEnabled),
            swizzledSelector: #selector(swizzledLocationServicesEnabled)
        )

        SwizzleManager.swizzle(
            CLLocationManager.self,
            originalSelector: #selector(startUpdatingLocation),
            swizzledSelector: #selector(swizzledStartUpdatingLocation)
        )

        SwizzleManager.swizzle(
            CLLocationManager.self,
            originalSelector: #selector(requestLocation),
            swizzledSelector: #selector(swizzedRequestLocation)
        )

        SwizzleManager.swizzle(
            CLLocationManager.self,
            originalSelector: #selector(getter: location),
            swizzledSelector: #selector(swizzedLocation)
        )
    }

    // MARK: - Methods

    private var simulatedLocation: CLLocation? { LocationToolkit.shared.simulatedLocation }

    @objc dynamic func swizzledInit() -> CLLocationManager {
        let manager = self.swizzledInit()
        CLLocationManagerTracker.add(manager: manager)
        return manager
    }

    @objc func swizzledLocationServicesEnabled() -> Bool {
        return true
    }

    @objc func swizzledStartUpdatingLocation() {
        if let simulatedLocation {
            if
                let delegate,
                delegate.responds(to: #selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
            {
                delegate.locationManager!(self, didUpdateLocations: [simulatedLocation])
            }
        } else {
            swizzledStartUpdatingLocation()
        }
    }

    @objc func swizzedRequestLocation() {
        if let simulatedLocation {
            delegate?.locationManager?(self, didUpdateLocations: [simulatedLocation])
        } else {
            if delegate != nil {
                swizzedRequestLocation()
            }
        }
    }

    @objc func swizzedLocation() -> CLLocation {
        if let simulatedLocation {
            return simulatedLocation
        } else {
            return swizzedLocation()
        }
    }
}
