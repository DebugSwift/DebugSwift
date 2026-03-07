//
//  SnapshotViewConfiguration.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 3/31/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

/// Configuration options for the 3D snapshot view.
final class SnapshotViewConfiguration: NSObject {
    /// Attributes used to customize the header rendered above the UI element.
    final class HeaderAttributes: NSObject {
        /// The background color of the header rendered above each view
        /// that has name text.
        var color = UIColor.darkGray

        /// The corner radius of the header background.
        var cornerRadius: CGFloat = 8.0

        /// The top and bottom inset between the header and the name text.
        var verticalInset: CGFloat = 8.0

        /// The font used to render the name text in the header.
        var font = UIFont.boldSystemFont(ofSize: 13)
    }

    /// The maximum allowed texture size for view snapshots. Views larger than this will be scaled down.
    /// Default is 8192 to match Metal's maximum texture size.
    var maxTextureSize: CGFloat = 8192

    /// The interpolation quality used when scaling down large views.
    /// Default is .high for better visual quality.
    var scaleInterpolationQuality: CGInterpolationQuality = .high

    /// The spacing between layers along the z-axis.
    var zSpacing: Float = 20.0

    /// The minimum spacing between layers along the z-axis.
    var minimumZSpacing: Float = .zero

    /// The maximum spacing between layers on the z-axis.
    var maximumZSpacing: Float = 100

    /// The scene's background color, which gets rendered behind
    /// all content.
    var backgroundColor = UIColor.white

    /// The color of the highlight overlaid on top of a UI element when it
    /// is selected.
    var highlightColor = UIColor(red: .zero, green: .zero, blue: 1.0, alpha: 0.5)

    /// The attributes for a header of normal importance.
    var normalHeaderAttributes: HeaderAttributes = {
        var attributes = HeaderAttributes()
        attributes.color = UIColor(red: 0.000, green: 0.533, blue: 1.000, alpha: 0.900)
        return attributes
    }()

    /// The attributes for a header of higher importance.
    var importantHeaderAttributes: HeaderAttributes = {
        var attributes = HeaderAttributes()
        attributes.color = UIColor(red: 0.961, green: 0.651, blue: 0.137, alpha: 0.900)
        return attributes
    }()

    /// The font used to render the description for a selected element.
    var descriptionFont = UIFont.systemFont(ofSize: 14)

    override init() {
        super.init()
    }
}
