//
//  GridOverlayColorScheme.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class GridOverlayColorScheme: Equatable {
    static func == (lhs: GridOverlayColorScheme, rhs: GridOverlayColorScheme) -> Bool {
        lhs.primaryColor == rhs.primaryColor && rhs.secondaryColor == lhs.secondaryColor
    }

    // MARK: - Properties

    private(set) var primaryColor: UIColor
    private(set) var secondaryColor: UIColor

    // MARK: - Initialization

    init(primaryColor: UIColor, secondaryColor: UIColor) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }

    final class func colorScheme(
        withPrimaryColor primaryColor: UIColor,
        secondaryColor: UIColor
    ) -> GridOverlayColorScheme {
        GridOverlayColorScheme(primaryColor: primaryColor, secondaryColor: secondaryColor)
    }
}
