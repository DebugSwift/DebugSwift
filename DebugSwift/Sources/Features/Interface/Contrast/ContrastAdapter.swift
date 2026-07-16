//
//  ContrastAdapter.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import UIKit

// MARK: - #10 Color Contrast Checker — UIKit adapter

/// UIKit adapter bridging `UIColor` ↔ normalized RGB tuples for
/// `ContrastChecker`, and rendering a human-readable result.
enum ContrastAdapter {

    /// Extract normalized `(red, green, blue)` from a `UIColor`.
    static func rgb(from color: UIColor) -> (red: Double, green: Double, blue: Double) {
        var redComponent: CGFloat = 0
        var greenComponent: CGFloat = 0
        var blueComponent: CGFloat = 0
        var alphaComponent: CGFloat = 0
        color.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: &alphaComponent)
        return (Double(redComponent), Double(greenComponent), Double(blueComponent))
    }

    /// Contrast ratio for two `UIColor`s.
    static func ratio(foreground: UIColor, background: UIColor) -> Double {
        ContrastChecker.ratio(foreground: rgb(from: foreground), background: rgb(from: background))
    }

    /// Grade for two `UIColor`s.
    static func grade(foreground: UIColor, background: UIColor) -> ContrastGrade {
        ContrastChecker.grade(ratio(foreground: foreground, background: background))
    }

    /// Human-readable report string for a foreground/background pair.
    static func report(foreground: UIColor, background: UIColor) -> String {
        let contrastRatio = ratio(foreground: foreground, background: background)
        let contrastGrade = ContrastChecker.grade(contrastRatio)
        return String(format: "Ratio %.2f — %@", contrastRatio, contrastGrade.rawValue.uppercased())
    }
}
