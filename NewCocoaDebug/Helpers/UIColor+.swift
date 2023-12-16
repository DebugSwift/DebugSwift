//
//  UIColor.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UIColor {
    static func randomColor() -> UIColor {
        let red = CGFloat(arc4random() % 256) / 255.0
        let green = CGFloat(arc4random() % 256) / 255.0
        let blue = CGFloat(arc4random() % 256) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
