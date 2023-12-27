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
    static let ballViewSize = CGSize(
        width: 18,
        height: 18
    )
    static let ballRect = CGRect(
        x: .zero,
        y: screenHeight * 0.3,
        width: 40,
        height: 40
    )
    static let padding: CGFloat = .zero
    static let topSafeAreaPadding = WindowManager.window.safeAreaInsets.top
    static let bottomSafeAreaPadding = WindowManager.window.safeAreaInsets.bottom

    // Movable view in the middle
    static let kUpBallViewFloatWidth: CGFloat = 60
    static let kUpBallViewFloatHeight: CGFloat = 60
}
