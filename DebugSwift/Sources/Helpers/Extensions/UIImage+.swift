//
//  UIImage+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UIImage {
    static func named(_ imageName: String, default: String? = nil) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage.init(systemName: imageName)
        } else {
            return `default`?.image(with: [.foregroundColor: Theme.shared.setupBackgroundColor()])
        }
    }

    func outline() -> UIImage? {
        guard let cgImage = cgImage else { return nil }

        let size = CGSize(width: cgImage.width, height: cgImage.height)

        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.draw(in: rect, blendMode: .normal, alpha: 1.0)

        // Set the stroke color and width
        context.setStrokeColor(Theme.shared.setupBackgroundColor().cgColor)
        let strokeWidth = Double(cgImage.height) * 0.01
        context.setLineWidth(strokeWidth)

        // Draw the stroke
        context.stroke(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
