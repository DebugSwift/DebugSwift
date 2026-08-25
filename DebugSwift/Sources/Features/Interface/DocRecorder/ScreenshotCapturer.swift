//
//  ScreenshotCapturer.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Foundation
import UIKit

@MainActor
final class ScreenshotCapturer {
    private let overlayWindowLevel: UIWindow.Level = .alert + 3

    func captureScreenshot() -> UIImage? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            return nil
        }

        let windows = windowScene.windows.filter { window in
            !window.isHidden && window.windowLevel < overlayWindowLevel
        }

        guard !windows.isEmpty else { return nil }

        let sceneRect = windows.reduce(CGRect.zero) { $0.union($1.frame) }
        let renderer = UIGraphicsImageRenderer(size: sceneRect.size)

        return renderer.image { context in
            context.cgContext.translateBy(x: -sceneRect.origin.x, y: -sceneRect.origin.y)
            for window in windows {
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
        }
    }

    func annotateWithCircle(image: UIImage, location: CGPoint, stepNumber: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            image.draw(at: .zero)

            let cgContext = context.cgContext
            let circleRadius: CGFloat = 30
            let circleRect = CGRect(
                x: location.x - circleRadius,
                y: location.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            )

            cgContext.setFillColor(UIColor.systemRed.withAlphaComponent(0.7).cgColor)
            cgContext.setStrokeColor(UIColor.systemRed.cgColor)
            cgContext.setLineWidth(3)

            cgContext.fillEllipse(in: circleRect)
            cgContext.strokeEllipse(in: circleRect)

            let numberString = "\(stepNumber)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.white,
            ]

            let textSize = numberString.size(withAttributes: attributes)
            let textRect = CGRect(
                x: location.x - textSize.width / 2,
                y: location.y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )

            numberString.draw(in: textRect, withAttributes: attributes)
        }
    }

    func annotateWithArrow(
        image: UIImage,
        location: CGPoint,
        direction: RecordingSession.ScrollDirection
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            image.draw(at: .zero)

            let cgContext = context.cgContext
            cgContext.setStrokeColor(UIColor.systemRed.cgColor)
            cgContext.setLineWidth(5)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            let arrowLength: CGFloat = 60
            let arrowHeadLength: CGFloat = 20
            let arrowHeadAngle: CGFloat = .pi / 6

            let arrowDirection = direction.arrowDirection

            let endPoint: CGPoint
            switch arrowDirection {
            case .up:
                endPoint = CGPoint(x: location.x, y: location.y - arrowLength)
            case .down:
                endPoint = CGPoint(x: location.x, y: location.y + arrowLength)
            case .left:
                endPoint = CGPoint(x: location.x - arrowLength, y: location.y)
            case .right:
                endPoint = CGPoint(x: location.x + arrowLength, y: location.y)
            }

            cgContext.move(to: location)
            cgContext.addLine(to: endPoint)
            cgContext.strokePath()

            let angle: CGFloat
            switch arrowDirection {
            case .up:
                angle = .pi / 2
            case .down:
                angle = -.pi / 2
            case .left:
                angle = 0
            case .right:
                angle = .pi
            }

            let arrowHead1 = CGPoint(
                x: endPoint.x + arrowHeadLength * cos(angle + arrowHeadAngle),
                y: endPoint.y + arrowHeadLength * sin(angle + arrowHeadAngle)
            )

            let arrowHead2 = CGPoint(
                x: endPoint.x + arrowHeadLength * cos(angle - arrowHeadAngle),
                y: endPoint.y + arrowHeadLength * sin(angle - arrowHeadAngle)
            )

            cgContext.move(to: endPoint)
            cgContext.addLine(to: arrowHead1)
            cgContext.move(to: endPoint)
            cgContext.addLine(to: arrowHead2)
            cgContext.strokePath()
        }
    }
}
