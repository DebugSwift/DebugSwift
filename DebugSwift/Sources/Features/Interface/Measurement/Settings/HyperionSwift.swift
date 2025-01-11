//
//  HyperionSwift.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

public class HyperionSwift {

    public static func present(in window: UIWindow) {
        MeasurementWindowManager.attachedWindow = window
    }
}
