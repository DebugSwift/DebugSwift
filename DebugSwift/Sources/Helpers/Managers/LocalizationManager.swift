//
//  LocalizationManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/03/24.
//

import Foundation
import UIKit
import SwiftUI

class LocalizationManager {

    @UserDefaultAccess(key: .languages, defaultValue: getCurrentLocalization())
    static var currentLocalization {
        didSet {
            var allLocations = getAllLocalizations()
            allLocations.removeAll(where: { $0 == currentLocalization })
            allLocations.insert(currentLocalization, at: .zero)
            UserDefaults.standard.setValue(allLocations, forKey: "AppleLanguages")
        }
    }

    static func setLocalization(_ languageCode: String) {
        currentLocalization = languageCode
        LocalizeManager.shared.loadBundle()
        resetApp()
    }

    static func getCurrentLocalization() -> String {
        return UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first ?? "en"
    }

    static func getAllLocalizations() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? ["en"]
    }

    static var localizationFile: String {
        let localization = currentLocalization.replacingOccurrences(of: "_", with: "-")

        return localization == "pt-BR" ? currentLocalization : currentLocalization.replacingOccurrences(of: "-BR", with: "")
    }

    static func resetApp() {
        // NOT WORK
        let windows = UIApplication.shared.windows
        for window in windows {
            for controller in (window.rootViewController as? UINavigationController)?.viewControllers ?? [] {
                controller.viewDidLoad()
//                window.rootViewController?.view.addSubview(view)
//                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

extension Bundle {
    static func swizzleLocalization() {
        let orginalSelector = #selector(localizedString(forKey:value:table:))
        guard let orginalMethod = class_getInstanceMethod(self, orginalSelector) else { return }

        let mySelector = #selector(myLocaLizedString(forKey:value:table:))
        guard let myMethod = class_getInstanceMethod(self, mySelector) else { return }

        if class_addMethod(self, orginalSelector, method_getImplementation(myMethod), method_getTypeEncoding(myMethod)) {
            class_replaceMethod(self, mySelector, method_getImplementation(orginalMethod), method_getTypeEncoding(orginalMethod))
        } else {
            method_exchangeImplementations(orginalMethod, myMethod)
        }
    }

    @objc private func myLocaLizedString(forKey key: String, value: String?, table: String?) -> String {
        if resourcePath?.contains("lproj") == true {
            return self.myLocaLizedString(forKey: key, value: value, table: table)
        }
        guard let bundlePath = path(forResource: LocalizationManager.localizationFile, ofType: "lproj"),
            let bundle = Bundle(path: bundlePath) else {
                return Bundle.main.myLocaLizedString(forKey: key, value: value, table: table)
        }
        return bundle.myLocaLizedString(forKey: key, value: value, table: table)
    }
}
