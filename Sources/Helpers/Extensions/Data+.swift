//
//  Data+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

extension Data {
    func formattedSize() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB, .useGB]

        return byteCountFormatter.string(fromByteCount: Int64(self.count))
    }

    func formattedString() -> String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            if let formattedString = String(data: jsonData, encoding: .utf8) {
                return formattedString
            }
        } catch {
            Debug.print("Error formatting JSON: \(error)")
        }

        return ""
    }
}
