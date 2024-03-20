//
//  LocalizationManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

final class LocalizeManager {
    static let shared = LocalizeManager()

    private let supportedLanguages = ["pt_BR", "en"]

    private init() {}

    var currentLanguage: String {
        if LocalizationManager.currentLocalization.contains("pt") {
            return supportedLanguages[0]
        } else {
            return supportedLanguages[1]
        }
    }

    private var bundle: Bundle?

    func localizedString(_ key: String, _ args: CVarArg...) -> String {
        guard let format = bundle?.localizedString(forKey: key, value: nil, table: nil) else {
            return key
        }
        return String(format: format, locale: Locale.current, arguments: args)
    }

    func loadBundle() {
        guard
            let path = Bundle.module.path(
                forResource: currentLanguage,
                ofType: "lproj"
            ),
            let bundle = Bundle(path: path)
        else {
            self.bundle = Bundle.module
            return
        }
        self.bundle = bundle
    }
}

extension String {
    func localized(_ args: CVarArg...) -> String {
        LocalizeManager.shared.localizedString(self, args)
    }
}
