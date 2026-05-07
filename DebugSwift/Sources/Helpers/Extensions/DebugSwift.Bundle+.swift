//
//  Bundle+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

extension Bundle {
    #if !SWIFT_PACKAGE
    static let module: Bundle = {
        let myBundle = Bundle(for: FloatViewManager.self)
        guard let resourceBundleURL = myBundle.url(
            forResource: "DebugSwift", withExtension: "bundle"
        )
        else { fatalError("DebugSwift.bundle not found!") }

        guard let resourceBundle = Bundle(url: resourceBundleURL)
        else { fatalError("Cannot access DebugSwift.bundle!") }

        return resourceBundle
    }()
    #endif
    
    var displayName: String? {
        return infoDictionary?["CFBundleDisplayName"] as? String ??
               infoDictionary?["CFBundleName"] as? String
    }
}
