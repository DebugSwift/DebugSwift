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
        guard let modelUrl =  model.url?.absoluteString.lowercased(), !modelUrl.isEmpty else {
            return false
        }
        
        if !DebugSwift.Network.shared.onlyURLs.isEmpty {
            if !matchesAnyPattern(modelUrl, patterns: DebugSwift.Network.shared.onlyURLs) {
                return false
            }
        } else if matchesAnyPattern(modelUrl, patterns: DebugSwift.Network.shared.ignoredURLs) {
            return false
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
    
    private func matchesAnyPattern(_ value: String, patterns: [String]) -> Bool {
        patterns.contains { pattern in
            let regex = wildcardToRegex(pattern)
            return value.range(of: regex, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    private func wildcardToRegex(_ pattern: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
        return escaped.replacingOccurrences(of: "\\*", with: ".*")
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
