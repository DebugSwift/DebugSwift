//
//  ColorPaletteModels.swift
//  DebugSwift
//
//  Value types describing a snapshot of colors extracted from a view tree.
//

import UIKit

/// File format the snapshot can be exported to.
public enum ColorPaletteExportFormat: String, CaseIterable {
    case swift
    case css
    case json
    case figma
    case tailwind
    case documentation

    public var fileExtension: String {
        switch self {
        case .swift: return "swift"
        case .css: return "css"
        case .json, .figma: return "json"
        case .tailwind: return "js"
        case .documentation: return "md"
        }
    }

    public var displayName: String {
        switch self {
        case .swift: return "Swift (UIColor)"
        case .css: return "CSS Variables"
        case .json: return "JSON Tokens"
        case .figma: return "Figma Tokens"
        case .tailwind: return "Tailwind Config"
        case .documentation: return "Markdown Docs"
        }
    }
}

enum ColorProperty: String {
    case backgroundColor
    case tintColor
    case textColor
    case borderColor
    case shadowColor

    var displayName: String {
        switch self {
        case .backgroundColor: return "Background"
        case .tintColor: return "Tint"
        case .textColor: return "Text"
        case .borderColor: return "Border"
        case .shadowColor: return "Shadow"
        }
    }
}

struct ColorLocation {
    let viewClassName: String
    let property: ColorProperty
}

enum ColorCategory: String, CaseIterable {
    case primary
    case secondary
    case background
    case text
    case accent
    case semantic

    var displayName: String {
        switch self {
        case .primary: return "Primary Colors"
        case .secondary: return "Secondary Colors"
        case .background: return "Background Colors"
        case .text: return "Text Colors"
        case .accent: return "Accent Colors"
        case .semantic: return "Semantic Colors"
        }
    }

    var sortOrder: Int {
        switch self {
        case .primary: return 0
        case .accent: return 1
        case .semantic: return 2
        case .background: return 3
        case .text: return 4
        case .secondary: return 5
        }
    }
}

/// A single color discovered in the view tree.
struct ColorInfo: Identifiable {
    let id: UUID
    let color: UIColor
    var name: String?
    var usageCount: Int
    var locations: [ColorLocation]
    let hex: String
    let red: Int
    let green: Int
    let blue: Int
    let hue: CGFloat
    let saturation: CGFloat
    let brightness: CGFloat
    let alpha: CGFloat

    var rgbString: String {
        "RGB(\(red), \(green), \(blue))"
    }

    var hsbString: String {
        let degrees = Int(hue * 360)
        let s = Int(saturation * 100)
        let b = Int(brightness * 100)
        return "HSB(\(degrees)°, \(s)%, \(b)%)"
    }

    var cmykString: String {
        let r = CGFloat(red) / 255.0
        let g = CGFloat(green) / 255.0
        let b = CGFloat(blue) / 255.0
        let k = 1 - max(r, g, b)
        guard k < 1 else { return "CMYK(0%, 0%, 0%, 100%)" }
        let c = (1 - r - k) / (1 - k)
        let m = (1 - g - k) / (1 - k)
        let y = (1 - b - k) / (1 - k)
        return String(
            format: "CMYK(%d%%, %d%%, %d%%, %d%%)",
            Int(c * 100), Int(m * 100), Int(y * 100), Int(k * 100)
        )
    }

    var componentBreakdown: [(className: String, count: Int)] {
        var counts: [String: Int] = [:]
        for location in locations {
            counts[location.viewClassName, default: 0] += 1
        }
        return counts
            .map { (className: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

struct ColorGroup {
    let name: String
    let colors: [ColorInfo]
    let category: ColorCategory

    var totalUsage: Int {
        colors.reduce(0) { $0 + $1.usageCount }
    }

    var primary: ColorInfo? {
        colors.max(by: { $0.usageCount < $1.usageCount })
    }
}

struct PaletteIssue {
    enum Kind {
        case similarColors(count: Int, sample: String)
        case lowContrast(foreground: String, background: String, ratio: CGFloat)
        case notInBrandPalette(hex: String)
        case colorBlindUnfriendly(hex: String)
    }

    let kind: Kind
    let message: String
}

struct PaletteStatistics {
    let totalColors: Int
    let totalGroups: Int
    let totalUsages: Int
    let mostUsed: ColorInfo?
    let leastUsed: ColorInfo?
    let issues: [PaletteIssue]
}

/// Result of extracting colors from a view tree. Use `export(as:)` to
/// serialize the snapshot in the desired format.
public struct ColorPaletteSnapshot {

    /// Source screen the snapshot was taken from, if it could be inferred.
    public let screenName: String?

    /// When the snapshot was taken.
    public let extractedAt: Date

    /// Number of distinct colors found.
    public var totalColors: Int { statistics.totalColors }

    /// Total number of usage sites across the view tree.
    public var totalUsages: Int { statistics.totalUsages }

    /// Localized issue messages (similar colors, low contrast, brand drift, etc.).
    public var issues: [String] { statistics.issues.map(\.message) }

    /// Render the snapshot in one of the supported formats.
    public func export(as format: ColorPaletteExportFormat) -> String {
        ColorPaletteExporter.export(self, as: format)
    }

    let colors: [ColorInfo]
    let groups: [ColorGroup]
    let statistics: PaletteStatistics

    init(
        colors: [ColorInfo],
        groups: [ColorGroup],
        statistics: PaletteStatistics,
        extractedAt: Date,
        screenName: String?
    ) {
        self.colors = colors
        self.groups = groups
        self.statistics = statistics
        self.extractedAt = extractedAt
        self.screenName = screenName
    }
}
