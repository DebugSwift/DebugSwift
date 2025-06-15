//
//  HyperionSwift.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

@MainActor
public class HyperionSwift {

    private init() {}
    public static let shared = HyperionSwift()

    public func activateMeasurement() {
        // Get the app's main window, not DebugSwift's window
        // This ensures we measure the actual app UI, not the debug interface
        MeasurementWindowManager.attachedWindow = MeasurementWindowManager.appMainWindow
    }
    
    public func deactivateMeasurement() {
        MeasurementWindowManager.attachedWindow = nil
    }
}
