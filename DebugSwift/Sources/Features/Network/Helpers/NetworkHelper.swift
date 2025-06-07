//
//  NetworkHelper.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class NetworkHelper: @unchecked Sendable {
    static let shared = NetworkHelper()

    var mainColor: UIColor
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
        WebSocketMonitor.shared.enable()
    }

    func disable() {
        guard isNetworkEnable else { return }
        isNetworkEnable = false
        CustomHTTPProtocol.stop()
        WebSocketMonitor.shared.disable()
    }
}
