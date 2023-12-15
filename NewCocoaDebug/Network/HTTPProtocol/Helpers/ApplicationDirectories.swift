//
//  ApplicationDirectories.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

class ApplicationDirectories {
    static let shared = ApplicationDirectories()

    var support: URL {
        guard let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to retrieve application support directory.")
        }
        return supportDirectory
    }
}
