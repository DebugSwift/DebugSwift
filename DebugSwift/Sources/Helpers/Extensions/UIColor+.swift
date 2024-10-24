//
//  UIColor+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init?(hexString: String) {
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xff0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00ff00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000ff) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    static func randomColor() -> UIColor {
        let red = CGFloat(arc4random() % 256) / 255.0
        let green = CGFloat(arc4random() % 256) / 255.0
        let blue = CGFloat(arc4random() % 256) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        // Convert hex string to an integer
        let hexInt = Int(UIColor.intFromHexString(hex: hex))
        let red = CGFloat((hexInt & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexInt & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexInt & 0xff) >> 0) / 255.0

        // Create color object, specifying alpha as well
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func intFromHexString(hex hexStr: String) -> UInt32 {
        var hexInt: UInt32 = 0
        // Create scanner
        let scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        scanner.scanHexInt32(&hexInt)
        return hexInt
    }

    var hexString: String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "No color"
        }

        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])

        let hexString = String(
            format: "#%02lX%02lX%02lX",
            lroundf(red * 255),
            lroundf(green * 255),
            lroundf(blue * 255)
        )

        return hexString
    }
}

@available(iOS 13.0, *)
extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init {
            switch $0.userInterfaceStyle {
            case .dark: dark
            default: light
            }
        }
    }
}
