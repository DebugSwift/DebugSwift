//
//  BatteryMetrics.swift
//  DebugSwift
//
//  Created by emircan.saglam on 7.06.2026.
//

import UIKit

struct BatterySnapshot {
    let level: Float
    let state: UIDevice.BatteryState
    let timestamp: Date
}

enum EnergyImpactLevel: Int {
    case veryLow = 1
    case low = 2
    case moderate = 3
    case high = 4
    case veryHigh = 5

    var label: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }

    var color: UIColor {
        switch self {
        case .veryLow: return .systemGreen
        case .low: return .systemGreen
        case .moderate: return .systemYellow
        case .high: return .systemOrange
        case .veryHigh: return .systemRed
        }
    }
}

struct EnergyImpact {
    let level: EnergyImpactLevel
    let cpuUsage: Double
    let isCharging: Bool

    static func calculate(cpuUsage: Double, state: UIDevice.BatteryState) -> EnergyImpact {
        let isCharging = state == .charging || state == .full
        let level: EnergyImpactLevel
        switch cpuUsage {
        case 0..<10: level = .veryLow
        case 10..<25: level = .low
        case 25..<50: level = .moderate
        case 50..<75: level = .high
        default: level = .veryHigh
        }
        return EnergyImpact(level: level, cpuUsage: cpuUsage, isCharging: isCharging)
    }
}
