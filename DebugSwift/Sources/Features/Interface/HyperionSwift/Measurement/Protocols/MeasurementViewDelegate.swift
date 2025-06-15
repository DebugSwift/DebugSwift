//
//  MeasurementViewDelegate.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

@MainActor
protocol MeasurementViewDelegate: AnyObject {
    var attachedWindow: UIWindow? { get }
}
