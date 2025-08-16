//
//  NetworkHelper.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class NetworkHelper: @unchecked Sendable {
    @MainActor static let shared = NetworkHelper()

    @MainActor var mainColor: UIColor
    @MainActor var protobufTransferMap: [String: [String]]?
    nonisolated(unsafe) var isNetworkEnable: Bool

    @MainActor private init() {
        self.mainColor = UIColor(hexString: "#42d459") ?? UIColor.green
        self.isNetworkEnable = false
    }

    @MainActor func enable() {
        guard !isNetworkEnable else { return }
        isNetworkEnable = true
        CustomHTTPProtocol.start()
        WebSocketMonitor.shared.enable()

        if !DebugSwift.App.shared.disableMethods.contains(.wkWebView) {
            WKWebViewNetworkMonitor.shared.install()
        }
    }

    @MainActor func disable() {
        guard isNetworkEnable else { return }
        isNetworkEnable = false
        CustomHTTPProtocol.stop()
        WebSocketMonitor.shared.disable()
        
        WKWebViewNetworkMonitor.shared.uninstall()
    }
}
