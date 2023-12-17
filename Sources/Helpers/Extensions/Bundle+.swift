//
//  Bundle+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

extension Bundle {
    static var debugBundle: Bundle {
        #if SWIFT_PACKAGE
        return SWIFTPM_MODULE_BUNDLE
        #else
        let podBundle = Bundle(for: TabBarController.self)
        if let bundleURL = podBundle.url(forResource: "DebugSwift", withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL) {
            return bundle
        }
        return Bundle.main
        #endif
    }
}
