//
//  ContrastChecker.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation

// MARK: - #10 Color Contrast Checker (pure WCAG math)

/// WCAG 2.x contrast grade for a foreground/background pair.
public enum ContrastGrade: String {
    case fail
    case levelAA
    case levelAAA
}

/// Pure WCAG 2.x relative-luminance and contrast-ratio math on RGB tuples
/// normalized to `[0, 1]`. No UIKit — fully testable on macOS.
public enum ContrastChecker {

    /// Relative luminance of an RGB color, per WCAG 2.x.
    public static func relativeLuminance(_ color: (red: Double, green: Double, blue: Double)) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(color.red)
            + 0.7152 * channel(color.green)
            + 0.0722 * channel(color.blue)
    }

    /// Contrast ratio between two colors (range 1.0–21.0).
    public static func ratio(
        foreground: (red: Double, green: Double, blue: Double),
        background: (red: Double, green: Double, blue: Double)
    ) -> Double {
        let lumForeground = relativeLuminance(foreground)
        let lumBackground = relativeLuminance(background)
        let lighter = max(lumForeground, lumBackground)
        let darker = min(lumForeground, lumBackground)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// WCAG grade for a contrast ratio.
    public static func grade(_ ratio: Double) -> ContrastGrade {
        if ratio >= 7 { return .levelAAA }
        if ratio >= 4.5 { return .levelAA }
        return .fail
    }
}
