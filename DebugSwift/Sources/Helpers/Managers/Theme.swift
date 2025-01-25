//
//  Theme.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 26/01/24.
//

import UIKit

public typealias Appearance = UIUserInterfaceStyle

//To prevent breaking change
extension UIUserInterfaceStyle {
    public static let automatic = UIUserInterfaceStyle.unspecified
}

class Theme {
    static var shared = Theme()

    //This is only really useful for iOS 12 and below now.
    @UserDefaultAccess(key: .darkMode, defaultValue: UIScreen.main.traitCollection.userInterfaceStyle == .dark)
    static var isDarkMode: Bool

    //This is only really useful for iOS 12 and below now. 
    private var appearance: Appearance = {
        return isDarkMode ? .dark : .light
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
