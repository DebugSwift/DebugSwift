//
//  HttpDatasource.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

class HttpDatasource {
    static let shared = HttpDatasource()

    var httpModels: [HttpModel] = []

    private init() {
//        httpModels = Array(repeating: HttpModel(), count: 1000 + 100)
    }

    func addHttpRequest(_ model: HttpModel) -> Bool {
        if model.url?.absoluteString.isEmpty == true {
            return false
        }

        // URL Filter, ignore case
        for urlString in (NetworkHelper.shared.ignoredURLs ?? []) {
            if model.url?.absoluteString.lowercased().contains(urlString.lowercased()) == true {
                return false
            }
        }

        // Maximum number limit
        if httpModels.count >= 1000 {
            if httpModels.count > 0 {
                httpModels.remove(at: 0)
            }
        }

        // Detect repeated
        guard !httpModels.contains(where: { $0.requestId == model.requestId }) else {
            return false
        }
        model.index = httpModels.count
        httpModels.append(model)
        return true
    }

    func reset() {
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
    private struct AssociatedKeys {
        static var requestId = "requestId"
        static var startTime = "startTime"
    }

    var requestId: String {
        get {
            if let id = objc_getAssociatedObject(self, AssociatedKeys.requestId) as? String {
                return id
            } else {
                let newValue = UUID().uuidString
                objc_setAssociatedObject(self, AssociatedKeys.requestId, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
                return newValue
            }
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.requestId, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    var startTime: NSNumber? {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.startTime) as? NSNumber
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.startTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
