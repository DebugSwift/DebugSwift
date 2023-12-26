//
//  FloatChat+DesignSystem.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2023/12/12.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

enum DSFloatChat {
    static let animationDuration = 0.3
    static let animationCancelMoveDuration = 0.35

    static let screenWidth: CGFloat = UIScreen.main.bounds.width
    static let screenHeight: CGFloat = UIScreen.main.bounds.height

    // Bottom black view
    static let bottomViewFloatWidth: CGFloat = 160
    static let bottomViewFloatHeight: CGFloat = 160
    static let minX = screenWidth - bottomViewFloatWidth
    static let minY = screenHeight - bottomViewFloatHeight
    static let ballRect = CGRect(
        x: screenWidth - 70,
        y: screenHeight * 0.3,
        width: 24,
        height: 24
    )
    static let padding: CGFloat = 10.0
    static let topSafeAreaPadding = WindowManager.window.safeAreaInsets.top
    static let bottomSafeAreaPadding = WindowManager.window.safeAreaInsets.bottom

    // Movable view in the middle
    static let kUpBallViewFloatWidth: CGFloat = 60
    static let kUpBallViewFloatHeight: CGFloat = 60
}
