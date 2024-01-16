//
//  Dictionary+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

extension [String: Any] {
    func formattedString() -> String {
        var formattedString = ""
        for (key, value) in self {
            formattedString += "\(key): \(value)\n"
        }
        return formattedString
    }
}

extension [AnyHashable: Any] {
    func convertKeysToString() -> [String: Value] {
        var result: [String: Value] = [:]

        for (key, value) in self {
            if let keyString = key as? String {
                result[keyString] = value
            }
        }

        return result
    }
}
