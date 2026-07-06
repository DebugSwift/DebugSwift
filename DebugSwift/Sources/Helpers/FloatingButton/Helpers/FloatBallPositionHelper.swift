import UIKit

@MainActor
enum FloatBallPositionHelper {
    private enum Layout {
        static let minLeadingCenterX: CGFloat = 20
        static let minTrailingInset: CGFloat = 20
        static let minTopCenterY: CGFloat = 80
        static let minBottomInset: CGFloat = 100
    }

    private static var savedX: Double {
        get {
            UserDefaults.standard.double(forKey: "debug_swift_float_ball_x") != 0
                ? UserDefaults.standard.double(forKey: "debug_swift_float_ball_x")
                : 20
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "debug_swift_float_ball_x")
        }
    }

    private static var savedY: Double {
        get {
            UserDefaults.standard.double(forKey: "debug_swift_float_ball_y") != 0
                ? UserDefaults.standard.double(forKey: "debug_swift_float_ball_y")
                : (UIScreen.main.bounds.height / 2 - 80.0)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "debug_swift_float_ball_y")
        }
    }

    static func restoreSavedPosition(in window: UIWindow) -> CGPoint {
        let position = clampedSavedPosition(in: window)
        persist(position)
        return position
    }

    static func finalizedDragPosition(from currentPosition: CGPoint, in window: UIWindow) -> CGPoint {
        let clamped = clampedPosition(currentPosition, in: window)
        let targetRange = centerXRange(in: window)
        let targetX =
            clamped.x <= window.bounds.width / 2
            ? targetRange.lowerBound
            : targetRange.upperBound

        let targetPosition = clampedPosition(
            .init(x: targetX, y: clamped.y),
            in: window
        )
        persist(targetPosition)
        return targetPosition
    }

    static func hiddenBottomFrame(in window: UIWindow) -> CGRect {
        .init(
            x: window.bounds.width,
            y: window.bounds.height,
            width: DSFloatChat.bottomViewFloatWidth,
            height: DSFloatChat.bottomViewFloatHeight
        )
    }

    static func visibleBottomFrame(in window: UIWindow) -> CGRect {
        .init(
            x: window.bounds.width - DSFloatChat.bottomViewFloatWidth,
            y: window.bounds.height - DSFloatChat.bottomViewFloatHeight,
            width: DSFloatChat.bottomViewFloatWidth,
            height: DSFloatChat.bottomViewFloatHeight
        )
    }

    private static func clampedSavedPosition(in window: UIWindow) -> CGPoint {
        clampedPosition(.init(x: savedX, y: savedY), in: window)
    }

    private static func persist(_ position: CGPoint) {
        savedX = Double(position.x)
        savedY = Double(position.y)
    }

    private static func clampedPosition(_ position: CGPoint, in window: UIWindow) -> CGPoint {
        let horizontalRange = centerXRange(in: window)
        let verticalRange = centerYRange(in: window)

        return CGPoint(
            x: min(max(position.x, horizontalRange.lowerBound), horizontalRange.upperBound),
            y: min(max(position.y, verticalRange.lowerBound), verticalRange.upperBound)
        )
    }

    private static func centerXRange(in window: UIWindow) -> ClosedRange<CGFloat> {
        let minX = window.safeAreaInsets.left + Layout.minLeadingCenterX
        let maxX = window.bounds.width - window.safeAreaInsets.right - Layout.minTrailingInset
        return minX...max(minX, maxX)
    }

    private static func centerYRange(in window: UIWindow) -> ClosedRange<CGFloat> {
        let minY = max(Layout.minTopCenterY, window.safeAreaInsets.top + Layout.minLeadingCenterX)
        let maxY = max(
            minY,
            window.bounds.height - max(Layout.minBottomInset, window.safeAreaInsets.bottom + 44)
        )
        return minY...maxY
    }
}
