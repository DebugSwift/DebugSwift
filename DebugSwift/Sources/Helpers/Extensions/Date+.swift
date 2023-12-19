//
//  Date+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

extension Date {
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    enum DateFormatType: String {
        case `default` = "HH:mm:ss - dd/MM/yyyy"
    }

    func formatted(_ format: DateFormatType = .default) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format.rawValue
        formatter.locale = Locale(identifier: "pt_BR")

        return formatter.string(from: self)
    }
}
