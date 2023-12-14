//
//  UIColor+Extensions.swift
//  ZZWeChatFloatView
//
//  Created by Matheus Gois on 26/11/21.
//  Copyright © 2021 apple. All rights reserved.
//

import UIKit

extension UIColor {
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
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        scanner.scanHexInt32(&hexInt)
        return hexInt
    }
}
