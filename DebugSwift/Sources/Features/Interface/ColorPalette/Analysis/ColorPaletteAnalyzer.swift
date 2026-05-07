//
//  ColorPaletteAnalyzer.swift
//  DebugSwift
//
//  Color grouping, contrast, color-blindness simulation, and brand-drift
//  detection. Perceptual distance uses CIEDE2000 in CIELAB space — see
//  Sharma, Wu, Dalal (2005), "The CIEDE2000 Color-Difference Formula".
//

import UIKit

enum ColorBlindnessType: String, CaseIterable {
    case protanopia
    case deuteranopia
    case tritanopia
    case achromatopsia

    var displayName: String {
        switch self {
        case .protanopia: return "Protanopia (red-blind)"
        case .deuteranopia: return "Deuteranopia (green-blind)"
        case .tritanopia: return "Tritanopia (blue-blind)"
        case .achromatopsia: return "Achromatopsia (no color)"
        }
    }
}

@MainActor
enum ColorPaletteAnalyzer {

    /// CIEDE2000 ΔE thresholds. ΔE ≈ 1 is the just-noticeable difference;
    /// ΔE ≈ 2-3 is the typical "same color" tolerance for design systems.
    static let groupingThreshold: CGFloat = 3.0
    static let brandDriftThreshold: CGFloat = 5.0
    static let colorBlindShiftThreshold: CGFloat = 12.0

    static func groupSimilarColors(_ colors: [ColorInfo]) -> [ColorGroup] {
        var processed: Set<UUID> = []
        var groups: [ColorGroup] = []

        for color in colors where !processed.contains(color.id) {
            var bucket: [ColorInfo] = [color]
            processed.insert(color.id)

            for other in colors where !processed.contains(other.id) {
                if deltaE2000(color.color, other.color) < groupingThreshold {
                    bucket.append(other)
                    processed.insert(other.id)
                }
            }

            let category = categorize(color)
            groups.append(ColorGroup(
                name: groupName(for: bucket, category: category),
                colors: bucket.sorted { $0.usageCount > $1.usageCount },
                category: category
            ))
        }

        return groups
    }

    static func detectIssues(
        colors: [ColorInfo],
        groups: [ColorGroup],
        brandColors: [UIColor]
    ) -> [PaletteIssue] {
        var issues: [PaletteIssue] = []

        for group in groups where group.colors.count > 1 {
            guard let primary = group.primary else { continue }
            issues.append(PaletteIssue(
                kind: .similarColors(count: group.colors.count, sample: primary.hex),
                message: "\(group.colors.count) similar \(group.category.displayName.lowercased()) found near \(primary.hex) — consider unifying"
            ))
        }

        let backgrounds = colors.filter { categorize($0) == .background }
        let foregrounds = colors.filter {
            let cat = categorize($0)
            return cat == .text || cat == .primary || cat == .accent
        }
        for fg in foregrounds {
            for bg in backgrounds {
                let ratio = contrastRatio(fg.color, bg.color)
                if ratio < 4.5 {
                    issues.append(PaletteIssue(
                        kind: .lowContrast(foreground: fg.hex, background: bg.hex, ratio: ratio),
                        message: String(format: "Low contrast: %@ on %@ (%.1f:1)", fg.hex, bg.hex, ratio)
                    ))
                }
            }
        }

        if !brandColors.isEmpty {
            let brandKeys = Set(brandColors.map { $0.hexString })
            for color in colors where color.usageCount >= 3 && !brandKeys.contains(color.hex) {
                let nearest = brandColors.min { lhs, rhs in
                    deltaE2000(lhs, color.color) < deltaE2000(rhs, color.color)
                }
                if let nearest, deltaE2000(nearest, color.color) < brandDriftThreshold {
                    issues.append(PaletteIssue(
                        kind: .notInBrandPalette(hex: color.hex),
                        message: "\(color.hex) (used \(color.usageCount)×) is close to brand \(nearest.hexString) but not exact"
                    ))
                }
            }
        }

        return issues
    }

    static func contrastRatio(_ a: UIColor, _ b: UIColor) -> CGFloat {
        let l1 = relativeLuminance(a)
        let l2 = relativeLuminance(b)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func wcagLevel(forContrast ratio: CGFloat, largeText: Bool = false) -> String {
        let aa: CGFloat = largeText ? 3.0 : 4.5
        let aaa: CGFloat = largeText ? 4.5 : 7.0
        if ratio >= aaa { return "AAA" }
        if ratio >= aa { return "AA" }
        return "Fail"
    }

    static func simulate(_ color: UIColor, type: ColorBlindnessType) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return color }

        if case .achromatopsia = type {
            let gray = 0.299 * r + 0.587 * g + 0.114 * b
            return UIColor(red: gray, green: gray, blue: gray, alpha: a)
        }

        let matrix = colorBlindMatrix(for: type)
        let nr = max(0, min(1, matrix.row0.x * r + matrix.row0.y * g + matrix.row0.z * b))
        let ng = max(0, min(1, matrix.row1.x * r + matrix.row1.y * g + matrix.row1.z * b))
        let nb = max(0, min(1, matrix.row2.x * r + matrix.row2.y * g + matrix.row2.z * b))
        return UIColor(red: nr, green: ng, blue: nb, alpha: a)
    }

    static func isColorBlindFriendly(_ color: UIColor) -> Bool {
        for type in ColorBlindnessType.allCases where type != .achromatopsia {
            let simulated = simulate(color, type: type)
            if deltaE2000(color, simulated) > colorBlindShiftThreshold { return false }
        }
        return true
    }

    static func categorize(_ info: ColorInfo) -> ColorCategory {
        let s = info.saturation
        let b = info.brightness
        let h = info.hue * 360

        if s < 0.08 {
            if b > 0.85 { return .background }
            if b < 0.25 { return .text }
            return .background
        }

        // Reds, greens, oranges → semantic
        if (h >= 0 && h <= 25) || h >= 340 { return .semantic }
        if h >= 95 && h <= 145 && s > 0.4 && b > 0.4 { return .semantic }
        if h >= 25 && h <= 55 && s > 0.5 { return .semantic }

        if s > 0.5 && b > 0.5 { return .primary }
        if s > 0.3 { return .accent }
        return .secondary
    }

    static func groupName(for bucket: [ColorInfo], category: ColorCategory) -> String {
        guard let primary = bucket.max(by: { $0.usageCount < $1.usageCount }) else {
            return category.displayName
        }
        let h = primary.hue * 360
        let hueName: String
        switch h {
        case 0..<15, 345...360: hueName = "Red"
        case 15..<45: hueName = "Orange"
        case 45..<65: hueName = "Yellow"
        case 65..<170: hueName = "Green"
        case 170..<200: hueName = "Teal"
        case 200..<255: hueName = "Blue"
        case 255..<290: hueName = "Indigo"
        case 290..<345: hueName = "Magenta"
        default: hueName = "Color"
        }

        if primary.saturation < 0.08 {
            if primary.brightness > 0.9 { return "White" }
            if primary.brightness < 0.15 { return "Black" }
            return "Gray \(Int(primary.brightness * 100))"
        }

        return "\(hueName) \(primary.hex)"
    }

    // MARK: - Color-blindness matrices

    private struct ColorMatrix {
        struct Row { let x, y, z: CGFloat }
        let row0: Row
        let row1: Row
        let row2: Row
    }

    private static func colorBlindMatrix(for type: ColorBlindnessType) -> ColorMatrix {
        switch type {
        case .protanopia:
            return ColorMatrix(
                row0: .init(x: 0.567, y: 0.433, z: 0.0),
                row1: .init(x: 0.558, y: 0.442, z: 0.0),
                row2: .init(x: 0.0, y: 0.242, z: 0.758)
            )
        case .deuteranopia:
            return ColorMatrix(
                row0: .init(x: 0.625, y: 0.375, z: 0.0),
                row1: .init(x: 0.7, y: 0.3, z: 0.0),
                row2: .init(x: 0.0, y: 0.3, z: 0.7)
            )
        case .tritanopia:
            return ColorMatrix(
                row0: .init(x: 0.95, y: 0.05, z: 0.0),
                row1: .init(x: 0.0, y: 0.433, z: 0.567),
                row2: .init(x: 0.0, y: 0.475, z: 0.525)
            )
        case .achromatopsia:
            return ColorMatrix(
                row0: .init(x: 0, y: 0, z: 0),
                row1: .init(x: 0, y: 0, z: 0),
                row2: .init(x: 0, y: 0, z: 0)
            )
        }
    }

    // MARK: - Relative luminance (WCAG)

    private static func relativeLuminance(_ color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
}

// MARK: - CIEDE2000 perceptual color difference

extension ColorPaletteAnalyzer {

    /// Perceptual color difference via CIEDE2000 in CIELAB space.
    /// Typical interpretations: <1 imperceptible, 1-2 close inspection,
    /// 2-10 perceivable at a glance, >10 clearly different.
    static func deltaE2000(_ a: UIColor, _ b: UIColor) -> CGFloat {
        deltaE2000(lab(from: a), lab(from: b))
    }

    private struct LabColor {
        let l: CGFloat
        let a: CGFloat
        let b: CGFloat
    }

    /// sRGB → CIELAB (D65 illuminant).
    private static func lab(from color: UIColor) -> LabColor {
        var r: CGFloat = 0, g: CGFloat = 0, bComp: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&r, green: &g, blue: &bComp, alpha: &alpha)

        func linearize(_ c: CGFloat) -> CGFloat {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let lr = linearize(r), lg = linearize(g), lb = linearize(bComp)

        // Linear sRGB → XYZ (D65, IEC 61966-2-1)
        let xyzX = lr * 0.4124564 + lg * 0.3575761 + lb * 0.1804375
        let xyzY = lr * 0.2126729 + lg * 0.7151522 + lb * 0.0721750
        let xyzZ = lr * 0.0193339 + lg * 0.1191920 + lb * 0.9503041

        // D65 reference white
        let xn: CGFloat = 0.95047, yn: CGFloat = 1.00000, zn: CGFloat = 1.08883

        func f(_ t: CGFloat) -> CGFloat {
            t > 0.008856 ? pow(t, 1.0 / 3.0) : (7.787 * t + 16.0 / 116.0)
        }
        let fx = f(xyzX / xn)
        let fy = f(xyzY / yn)
        let fz = f(xyzZ / zn)

        return LabColor(
            l: 116 * fy - 16,
            a: 500 * (fx - fy),
            b: 200 * (fy - fz)
        )
    }

    /// CIEDE2000 ΔE between two CIELAB colors with kL = kC = kH = 1.
    private static func deltaE2000(_ lab1: LabColor, _ lab2: LabColor) -> CGFloat {
        let twentyFive7 = pow(25.0 as CGFloat, 7)

        // Step 1: chroma + chroma-shifted a' (G compensates low-chroma reds).
        let c1 = sqrt(lab1.a * lab1.a + lab1.b * lab1.b)
        let c2 = sqrt(lab2.a * lab2.a + lab2.b * lab2.b)
        let cMean = (c1 + c2) / 2
        let g = 0.5 * (1 - sqrt(pow(cMean, 7) / (pow(cMean, 7) + twentyFive7)))
        let a1p = (1 + g) * lab1.a
        let a2p = (1 + g) * lab2.a

        // Step 2: shifted chroma + hue (degrees, 0…360).
        let c1p = sqrt(a1p * a1p + lab1.b * lab1.b)
        let c2p = sqrt(a2p * a2p + lab2.b * lab2.b)
        let h1p = huePrime(b: lab1.b, ap: a1p)
        let h2p = huePrime(b: lab2.b, ap: a2p)

        // Step 3: ΔL', ΔC', ΔH'
        let dL = lab2.l - lab1.l
        let dC = c2p - c1p
        let dh = hueDifference(h1p: h1p, h2p: h2p, c1p: c1p, c2p: c2p)
        let dH = 2 * sqrt(c1p * c2p) * sin(degreesToRadians(dh) / 2)

        // Step 4: weighting functions
        let lMean = (lab1.l + lab2.l) / 2
        let cMeanP = (c1p + c2p) / 2
        let hMeanP = hueMean(h1p: h1p, h2p: h2p, c1p: c1p, c2p: c2p)
        let t = 1
            - 0.17 * cos(degreesToRadians(hMeanP - 30))
            + 0.24 * cos(degreesToRadians(2 * hMeanP))
            + 0.32 * cos(degreesToRadians(3 * hMeanP + 6))
            - 0.20 * cos(degreesToRadians(4 * hMeanP - 63))

        let sL = 1 + (0.015 * pow(lMean - 50, 2)) / sqrt(20 + pow(lMean - 50, 2))
        let sC = 1 + 0.045 * cMeanP
        let sH = 1 + 0.015 * cMeanP * t

        let dTheta = 30 * exp(-pow((hMeanP - 275) / 25, 2))
        let rC = 2 * sqrt(pow(cMeanP, 7) / (pow(cMeanP, 7) + twentyFive7))
        let rT = -sin(degreesToRadians(2 * dTheta)) * rC

        let lTerm = dL / sL
        let cTerm = dC / sC
        let hTerm = dH / sH
        return sqrt(lTerm * lTerm + cTerm * cTerm + hTerm * hTerm + rT * cTerm * hTerm)
    }

    private static func huePrime(b: CGFloat, ap: CGFloat) -> CGFloat {
        if b == 0 && ap == 0 { return 0 }
        let degrees = atan2(b, ap) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }

    private static func hueDifference(
        h1p: CGFloat, h2p: CGFloat, c1p: CGFloat, c2p: CGFloat
    ) -> CGFloat {
        if c1p * c2p == 0 { return 0 }
        let diff = h2p - h1p
        if abs(diff) <= 180 { return diff }
        return diff > 180 ? diff - 360 : diff + 360
    }

    private static func hueMean(
        h1p: CGFloat, h2p: CGFloat, c1p: CGFloat, c2p: CGFloat
    ) -> CGFloat {
        if c1p * c2p == 0 { return h1p + h2p }
        if abs(h1p - h2p) <= 180 { return (h1p + h2p) / 2 }
        return (h1p + h2p < 360) ? (h1p + h2p + 360) / 2 : (h1p + h2p - 360) / 2
    }

    private static func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        degrees * .pi / 180
    }
}
