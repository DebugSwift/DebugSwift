//
//  ColorPaletteExtractor.swift
//  DebugSwift
//
//  Walks a view tree and records the colors set on each view.
//

import UIKit

@MainActor
final class ColorPaletteExtractor {

    static let shared = ColorPaletteExtractor()

    var brandColors: [UIColor] = []

    private init() {}

    func extract(from view: UIView? = nil, screenName: String? = nil) -> ColorPaletteSnapshot {
        let target = view ?? Self.preferredAppWindow() ?? UIApplication.keyWindow ?? UIWindow()
        var colorMap: [String: ColorInfo] = [:]
        traverse(target, into: &colorMap)

        let colors = Array(colorMap.values).sorted { $0.usageCount > $1.usageCount }

        let groups = ColorPaletteAnalyzer.groupSimilarColors(colors)
            .sorted { lhs, rhs in
                if lhs.category.sortOrder != rhs.category.sortOrder {
                    return lhs.category.sortOrder < rhs.category.sortOrder
                }
                return lhs.totalUsage > rhs.totalUsage
            }

        let issues = ColorPaletteAnalyzer.detectIssues(
            colors: colors,
            groups: groups,
            brandColors: brandColors
        )

        let statistics = PaletteStatistics(
            totalColors: colors.count,
            totalGroups: groups.count,
            totalUsages: colors.reduce(0) { $0 + $1.usageCount },
            mostUsed: colors.first,
            leastUsed: colors.last,
            issues: issues
        )

        return ColorPaletteSnapshot(
            colors: colors,
            groups: groups,
            statistics: statistics,
            extractedAt: Date(),
            screenName: screenName ?? Self.inferScreenName()
        )
    }

    private func traverse(_ view: UIView, into colorMap: inout [String: ColorInfo]) {
        if isOwnedByDebugSwift(view) { return }

        if let bg = view.backgroundColor, bg != .clear {
            record(bg, property: .backgroundColor, view: view, into: &colorMap)
        }

        if view.isTintColorMeaningful, let tint = view.tintColor {
            record(tint, property: .tintColor, view: view, into: &colorMap)
        }

        if let label = view as? UILabel {
            record(label.textColor, property: .textColor, view: view, into: &colorMap)
        }

        if let button = view as? UIButton, let titleColor = button.titleColor(for: .normal) {
            record(titleColor, property: .textColor, view: view, into: &colorMap)
        }

        if let textField = view as? UITextField, let textColor = textField.textColor {
            record(textColor, property: .textColor, view: view, into: &colorMap)
        }

        if let textView = view as? UITextView, let textColor = textView.textColor {
            record(textColor, property: .textColor, view: view, into: &colorMap)
        }

        if let cgBorder = view.layer.borderColor, view.layer.borderWidth > 0 {
            record(UIColor(cgColor: cgBorder), property: .borderColor, view: view, into: &colorMap)
        }

        if let cgShadow = view.layer.shadowColor, view.layer.shadowOpacity > 0 {
            record(UIColor(cgColor: cgShadow), property: .shadowColor, view: view, into: &colorMap)
        }

        for sub in view.subviews {
            traverse(sub, into: &colorMap)
        }
    }

    private func record(
        _ color: UIColor,
        property: ColorProperty,
        view: UIView,
        into colorMap: inout [String: ColorInfo]
    ) {
        let resolved = color.resolvedColor(with: view.traitCollection)
        let key = resolved.paletteKey
        let location = ColorLocation(
            viewClassName: String(describing: type(of: view)),
            property: property
        )

        if var existing = colorMap[key] {
            existing.usageCount += 1
            existing.locations.append(location)
            colorMap[key] = existing
            return
        }

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else { return }

        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0
        var alphaForHue: CGFloat = 0
        resolved.getHue(&h, saturation: &s, brightness: &br, alpha: &alphaForHue)

        colorMap[key] = ColorInfo(
            id: UUID(),
            color: resolved,
            name: nil,
            usageCount: 1,
            locations: [location],
            hex: resolved.hexString,
            red: Int((r * 255).rounded()),
            green: Int((g * 255).rounded()),
            blue: Int((b * 255).rounded()),
            hue: h,
            saturation: s,
            brightness: br,
            alpha: a
        )
    }

    private func isOwnedByDebugSwift(_ view: UIView) -> Bool {
        let className = String(describing: type(of: view))
        return className.hasPrefix("DebugSwift") || className.contains("FloatBall")
    }

    private static func inferScreenName() -> String? {
        guard let window = preferredAppWindow(),
              let top = UIApplication.topViewController(window.rootViewController) else {
            return nil
        }
        return String(describing: type(of: top))
    }

    /// The user's app window — i.e. not the DebugSwift overlay window.
    private static func preferredAppWindow() -> UIWindow? {
        let candidates = UIWindowScene._windows.filter { window in
            let className = String(describing: type(of: window))
            if className == "UITextEffectsWindow" { return false }
            if className == "CustomWindow" { return false }
            if window.windowLevel >= UIWindow.Level.alert { return false }
            return true
        }
        return candidates.first(where: { $0.isKeyWindow }) ?? candidates.first
    }
}

private extension UIColor {
    var paletteKey: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(
                format: "%02X%02X%02X%02X",
                Int((r * 255).rounded()),
                Int((g * 255).rounded()),
                Int((b * 255).rounded()),
                Int((a * 255).rounded())
            )
        }
        return hexString
    }
}

private extension UIView {
    var isTintColorMeaningful: Bool {
        self is UIButton
            || self is UISwitch
            || self is UISlider
            || self is UISegmentedControl
            || self is UIProgressView
            || self is UIActivityIndicatorView
            || self is UIImageView
    }
}
