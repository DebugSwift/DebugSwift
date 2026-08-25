//
//  HTTPURLResponse+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    func expires() -> Date? {
        if let cc = value(forHTTPHeaderField: "Cache-Control")?.lowercased(),
           let range = cc.range(of: "max-age="),
           let s = cc[range.upperBound...].components(separatedBy: ",").first,
           let age = TimeInterval(s) {
            return Date(timeIntervalSinceNow: age)
        }

        if let ex = value(forHTTPHeaderField: "Expires"),
           let exp = Date.dateFormatter.date(from: ex) {
            return exp
        }

        return nil
    }
}
