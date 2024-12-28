//
//  Theme.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 26/01/24.
//

import UIKit

public enum Appearance {
    case dark
    case light
    @available(iOS 13.0, *)
    case automatic
}

class Theme {
    static var shared = Theme()

    var appearance: Appearance = {
        if #available(iOS 13.0, *) {
            return .automatic
        } else {
            return .dark
        }
    }()

    var interfaceStyleColor: UIUserInterfaceStyle {
        switch appearance {
        case .dark: return .dark
        case .light: return .light
        case .automatic: return .unspecified
        }
    }

    var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            switch appearance {
            case .dark: return .black
            case .light: return .white
            case .automatic: return .systemBackground
            }
        } else {
            return appearance == .light ? .white : .black
        }
    }

    var fontColor: UIColor {
        if #available(iOS 13.0, *) {
            switch appearance {
            case .dark: return .white
            case .light: return .black
            case .automatic: return .label
            }
        } else {
            return appearance == .light ? .black : .white
        }
    }

    var statusFetchColor: UIColor {
        let light = UIColor(hexString: "#32CD32") ?? .green
        let dark = UIColor.green
        if #available(iOS 13.0, *) {
            switch appearance {
            case .dark: return dark
            case .light: return light
            case .automatic: return UIColor(light: light, dark: dark)
            }
        } else {
            return appearance == .light ? light : dark
        }
    }
}
