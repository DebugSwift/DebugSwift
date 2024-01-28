//
//  ThemeStyling.swift
//  DebugSwift
//
//  Created by Mochamad Rakha Luthfi Fahsya on 26/01/24.
//

import UIKit

public enum Appearance {
    case dark
    case light
}

class Theme {
    static var shared = Theme()
    
    var appearance: Appearance = .dark
    var fontColor: String = ""
    var backgroundColor: String = ""
    
    func setupInterfaceStyle() -> UIUserInterfaceStyle {
        return appearance == .dark ? .dark : .light
    }
    
    func setupBackgroundColor() -> UIColor {
        return appearance == .dark ? .black : .white
    }
    
    func setupFontColor() -> UIColor {
        return appearance == .dark ? .white : .black
    }
    
    func setupStatusFetchColor() -> UIColor {
        return appearance == .dark ? .green : UIColor(hexString: "#32CD32") ?? .green
    }
    
    func setAppearance(appearance: Appearance?) {
        let defaultAppearance = appearance
        self.appearance = defaultAppearance == .dark ? .dark : .light
    }
    
    func setCustomAppearance(backgroundColor: String, fontColor: String) {
        
    }
}
