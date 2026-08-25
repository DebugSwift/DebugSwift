//
//  HierarchyViewConfiguration.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/8/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

/// Configuration options for the hierarchy (tree) view.
final class HierarchyViewConfiguration: NSObject {
    /// The maximum depth that is rendered in the tree view. If the
    /// depth of the item exceeds this value, it will be hidden from
    /// view and can only be accessed by tapping the "Subtree" button
    /// of its parent node.
    ///
    /// Setting this to `nil` means there's no maximum.
    @objc var maxDepth: NSNumber? = 5

    /// The font used to render the names of the elements.
    @objc var nameFont = UIFont.preferredFont(forTextStyle: .body)

    /// The font used to render the frames of the elements.
    @objc var frameFont = UIFont.preferredFont(forTextStyle: .caption1)

    /// The colors of the lines displayed to show the depth of the tree.
    ///
    /// If the depth of a node exceeds the number of colors in this array,
    /// the colors will repeat from the beginning.
    @objc var lineColors = [
        UIColor(white: 0.2, alpha: 1.0),
        UIColor(white: 0.4, alpha: 1.0),
        UIColor(white: 0.6, alpha: 1.0),
        UIColor(white: 0.8, alpha: 1.0),
        UIColor(white: 0.9, alpha: 1.0),
        UIColor(white: 0.95, alpha: 1.0)
    ]

    /// The width of the lines drawn to show the depth of the tree.
    @objc var lineWidth: CGFloat = 1.0

    /// The spacing between the lines drawn to show the depth of the three.
    @objc var lineSpacing: CGFloat = 12.0
}
