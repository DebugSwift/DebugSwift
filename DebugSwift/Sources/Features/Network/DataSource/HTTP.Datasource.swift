//
//  HTTP.Datasource.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

final class HttpDatasource: @unchecked Sendable {
    static let shared = HttpDatasource()

    var httpModels: [HttpModel] = []

    func addHttpRequest(_ model: HttpModel) -> Bool {
        if model.url?.absoluteString.isEmpty == true {
            return false
        }

        if !DebugSwift.Network.shared.onlyURLs.isEmpty {
            if let modelUrl = model.url?.absoluteString.lowercased() {
                let found = DebugSwift.Network.shared.onlyURLs.contains { modelUrl.contains($0.lowercased()) }
                if !found {
                    return false
                }
            }
        } else {
            for urlString in DebugSwift.Network.shared.ignoredURLs {
                if model.url?.absoluteString.lowercased().contains(
                    urlString.lowercased()
                ) == true {
                    return false
                }
            }
        }

        // Maximum number limit
        if httpModels.count >= 10000 {
            if !httpModels.isEmpty {
                httpModels.remove(at: 0)
            }
        }

        // Detect repeated
        guard !httpModels.contains(where: { $0.requestId == model.requestId }) else {
            return false
        }
        model.index = httpModels.count
        
        // Check if decryption is enabled and try to decrypt response
        if DebugSwift.Network.shared.isDecryptionEnabled, let responseData = model.responseData {
            let encryptionService = DebugSwift.Network.shared.encryptionService
            model.isEncrypted = encryptionService.isEncrypted(responseData)
            
            if model.isEncrypted {
                // Try custom decryptor first
                model.decryptedResponseData = encryptionService.customDecrypt(responseData, for: model.url)

                // If custom decryptor didn't work, try with registered keys
                if model.decryptedResponseData == nil {
                    let decryptionKey = encryptionService.getDecryptionKey(for: model.url)
                    model.decryptedResponseData = encryptionService.decrypt(responseData, using: decryptionKey)
                }
            }
        }
        
        httpModels.append(model)
        return true
    }

    func removeAll() {
        httpModels.removeAll()
    }

    func remove(_ model: HttpModel) {
        for (index, obj) in httpModels.reversed().enumerated() {
            if obj.requestId == model.requestId {
                httpModels.remove(at: index)
            }
        }
    }
}

extension URLRequest {
    private enum AssociatedKeys {
        static let requestId = "requestId"
        static let startTime = "startTime"
    }

    var requestId: String {
        get {
            if let id = objc_getAssociatedObject(self, AssociatedKeys.requestId) as? String {
                return id
            }
            let newValue = UUID().uuidString
            objc_setAssociatedObject(
                self, AssociatedKeys.requestId, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
            return newValue
        }
        set {
            objc_setAssociatedObject(
                self, AssociatedKeys.requestId, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }
    }

    var startTime: NSNumber? {
        get {
            objc_getAssociatedObject(self, AssociatedKeys.startTime) as? NSNumber
        }
        set {
            objc_setAssociatedObject(
                self, AssociatedKeys.startTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
