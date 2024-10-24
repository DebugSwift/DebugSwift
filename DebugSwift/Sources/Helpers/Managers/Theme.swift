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
            .automatic
        } else {
            .dark
        }
    }()

    var interfaceStyleColor: UIUserInterfaceStyle {
        switch appearance {
        case .dark: .dark
        case .light: .light
        case .automatic: .unspecified
        }
    }

    var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            switch appearance {
            case .dark: .black
            case .light: .white
            case .automatic: .systemBackground
            }
        } else {
            appearance == .light ? .white : .black
        }
    }

    var fontColor: UIColor {
        if #available(iOS 13.0, *) {
            switch appearance {
            case .dark: .white
            case .light: .black
            case .automatic: .label
            }
        } else {
            appearance == .light ? .black : .white
        }
    }

    var statusFetchColor: UIColor {
        let light = UIColor(hexString: "#32CD32") ?? .green
        let dark = UIColor.green
        return if #available(iOS 13.0, *) {
            switch appearance {
            case .dark: dark
            case .light: light
            case .automatic: UIColor(light: light, dark: dark)
            }
        } else {
            appearance == .light ? light : dark
        }
    }
}
