//
//  Theme.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 26/01/24.
//

import UIKit

public typealias Appearance = UIUserInterfaceStyle

class Theme {
    static var shared = Theme()

    @UserDefaultAccess(key: .darkMode, defaultValue: UIScreen.main.traitCollection.userInterfaceStyle == .dark)
    static var darkMode: Bool

    private var appearance: Appearance = {
        return darkMode ? .dark : .light
    }()

    var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: .white, dark: .black)
        } else {
            return appearance ==  .light ? .white : .black
        }
    }

    var fontColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: .black, dark: .white)
        } else {
            return appearance == .light ? .black : .white
        }
    }

    var statusFetchColor: UIColor {
        let light = UIColor(hexString: "#32CD32") ?? .green
        let dark = UIColor.green

        if #available(iOS 13.0, *) {
            return UIColor(light: light, dark: dark)
        } else {
            return appearance == .light ? light : dark
        }
    }
}
