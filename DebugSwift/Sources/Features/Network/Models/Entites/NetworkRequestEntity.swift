//
//  NetworkRequestEntity.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 21/05/26.
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@Model
final class NetworkRequestEntity {
    @Attribute(.unique) var id: UUID
    var url: String?
    var requestData: Data?
    var responseData: Data?
    var requestId: String?
    var method: String?
    var statusCode: String?
    var mineType: String?
    var startTime: String?
    var endTime: String?
    var totalDuration: String?
    var isImage: Bool
    var isEncrypted: Bool
    var requestHeadersData: Data?
    var responseHeadersData: Data?
    var errorDescriptionText: String?
    var errorLocalizedDescriptionText: String?
    var size: String?
    var modelIndex: Int
    var mode: String
    var capturedAt: Date
    var createdAt: Date
    var session: NetworkSessionEntity?

    init(
        id: UUID = UUID(),
        url: String?,
        requestData: Data?,
        responseData: Data?,
        requestId: String?,
        method: String?,
        statusCode: String?,
        mineType: String?,
        startTime: String?,
        endTime: String?,
        totalDuration: String?,
        isImage: Bool,
        isEncrypted: Bool,
        requestHeadersData: Data?,
        responseHeadersData: Data?,
        errorDescriptionText: String?,
        errorLocalizedDescriptionText: String?,
        size: String?,
        modelIndex: Int,
        mode: String,
        capturedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.requestData = requestData
        self.responseData = responseData
        self.requestId = requestId
        self.method = method
        self.statusCode = statusCode
        self.mineType = mineType
        self.startTime = startTime
        self.endTime = endTime
        self.totalDuration = totalDuration
        self.isImage = isImage
        self.isEncrypted = isEncrypted
        self.requestHeadersData = requestHeadersData
        self.responseHeadersData = responseHeadersData
        self.errorDescriptionText = errorDescriptionText
        self.errorLocalizedDescriptionText = errorLocalizedDescriptionText
        self.size = size
        self.modelIndex = modelIndex
        self.mode = mode
        self.capturedAt = capturedAt
        self.createdAt = createdAt
    }
}

@available(iOS 17.0, *)
extension NetworkRequestEntity {
    func makeHttpModel() -> HttpModel {
        let model = HttpModel()
        model.url = url.flatMap(URL.init(string:))
        model.requestData = requestData
        model.responseData = responseData
        model.requestId = requestId
        model.method = method
        model.statusCode = statusCode
        model.mineType = mineType
        model.startTime = startTime
        model.endTime = endTime
        model.totalDuration = totalDuration
        model.isImage = isImage
        model.isEncrypted = isEncrypted
        model.requestHeaderFields = NetworkSessionPersistenceManager.decodeHeaders(requestHeadersData)
        model.responseHeaderFields = NetworkSessionPersistenceManager.decodeHeaders(responseHeadersData)
        model.errorDescription = errorDescriptionText
        model.errorLocalizedDescription = errorLocalizedDescriptionText
        model.size = size
        model.index = modelIndex
        return model
    }
}

@available(iOS 17.0, *)
extension NetworkSessionPersistenceManager.RequestRecord {
    func makeHttpModel() -> HttpModel {
        let model = HttpModel()
        model.url = url.flatMap(URL.init(string:))
        model.requestData = requestData
        model.responseData = responseData
        model.requestId = requestId
        model.method = method
        model.statusCode = statusCode
        model.mineType = mineType
        model.startTime = startTime
        model.endTime = endTime
        model.totalDuration = totalDuration
        model.isImage = isImage
        model.isEncrypted = isEncrypted
        model.requestHeaderFields = NetworkSessionPersistenceManager.decodeHeaders(requestHeadersData)
        model.responseHeaderFields = NetworkSessionPersistenceManager.decodeHeaders(responseHeadersData)
        model.errorDescription = errorDescriptionText
        model.errorLocalizedDescription = errorLocalizedDescriptionText
        model.size = size
        model.index = modelIndex
        return model
    }
}
#endif
