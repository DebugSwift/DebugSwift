//
//  NetworkHelper.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class NetworkHelper {
    static let shared = NetworkHelper()

    var mainColor: UIColor
    var ignoredURLs: [String]?
    var onlyURLs: [String]?
    var ignoredPrefixLogs: [String]?
    var onlyPrefixLogs: [String]?
    var protobufTransferMap: [String: [String]]?
    var isNetworkEnable: Bool

    private init() {
        self.mainColor = UIColor(hexString: "#42d459") ?? UIColor.green
        self.isNetworkEnable = false
    }

    func enable() {
        guard !isNetworkEnable else { return }
        isNetworkEnable = true
        CustomHTTPProtocol.start()
    }

    func disable() {
        guard isNetworkEnable else { return }
        isNetworkEnable = false
        CustomHTTPProtocol.stop()
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xff0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00ff00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000ff) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
