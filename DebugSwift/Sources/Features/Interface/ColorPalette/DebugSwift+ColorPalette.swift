//
//  DebugSwift+ColorPalette.swift
//  DebugSwift
//
//  Public namespace for the color palette extractor.
//

import UIKit

extension DebugSwift {

    /// Color palette extractor — surfaces every color set on the live view
    /// hierarchy, groups similar colors, flags drift from a brand palette,
    /// and exports the result in a handful of formats.
    ///
    /// The extractor is also reachable through the Interface tab in the
    /// debug menu. This namespace exists for callers that want to drive
    /// extraction programmatically.
    ///
    /// ```swift
    /// // Optional: register brand colors so drift surfaces as an issue.
    /// DebugSwift.ColorPalette.brandColors = [
    ///     UIColor(hex: "#007AFF"),
    ///     UIColor(hex: "#34C759")
    /// ]
    ///
    /// let snapshot = DebugSwift.ColorPalette.extract()
    /// let swiftCode = snapshot.export(as: .swift)
    /// ```
    @MainActor
    public enum ColorPalette {

        /// Brand colors used to flag drift in extracted palettes. When set,
        /// any color that's similar to but not exactly equal to a brand color
        /// is reported as a `notInBrandPalette` issue.
        public static var brandColors: [UIColor] {
            get { ColorPaletteExtractor.shared.brandColors }
            set { ColorPaletteExtractor.shared.brandColors = newValue }
        }

        /// Extract the palette of colors visible in `view` (defaults to the
        /// user's key window — i.e. the app's window, not the debug overlay).
        public static func extract(
            from view: UIView? = nil,
            screenName: String? = nil
        ) -> ColorPaletteSnapshot {
            ColorPaletteExtractor.shared.extract(from: view, screenName: screenName)
        }
    }
}
