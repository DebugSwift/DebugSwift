//
//  String+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension String {
    static let cell = "cell"

    /// Generates a `UIImage` instance from this string using a specified
    /// attributes and size.
    ///
    /// - Parameters:
    ///     - attributes: to draw this string with. Default is `nil`.
    ///     - size: of the image to return.
    /// - Returns: a `UIImage` instance from this string using a specified
    /// attributes and size, or `nil` if the operation fails.
    func image(with attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil) -> UIImage? {
        guard !isEmpty else { return nil }
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size).image { _ in
            (self as NSString).draw(
                in: CGRect(origin: .zero, size: size),
                withAttributes: attributes
            )
        }
    }

    func leftPadding(toLength: Int, withPad: String = " ") -> String {
        guard toLength > count else { return self }
        let padding = String(repeating: withPad, count: toLength - count)
        return padding + self
    }
}
