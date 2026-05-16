//
//  NetworkSessionPersistenceManager.swift
//  DebugSwift
//
//  Created by Adjie Satryo on 16/05/26.
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@Model
final class NetworkSessionEntity {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \NetworkRequestEntity.session)
    var requests: [NetworkRequestEntity]

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date? = nil,
        createdAt: Date = Date(),
        requests: [NetworkRequestEntity] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = createdAt
        self.requests = requests
    }
}

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
@MainActor
final class NetworkSessionPersistenceManager {
    private enum Preference {
        static let enabledKey = "DebugSwift.Network.SessionPersistence.Enabled"
        static let retentionDaysKey = "DebugSwift.Network.SessionPersistence.RetentionDays"
        static let defaultRetentionDays = 7
    }

    struct RequestSnapshot: Sendable {
        let urlString: String?
        let requestData: Data?
        let responseData: Data?
        let requestId: String?
        let method: String?
        let statusCode: String?
        let mineType: String?
        let startTime: String?
        let endTime: String?
        let totalDuration: String?
        let isImage: Bool
        let isEncrypted: Bool
        let requestHeaders: [String: String]?
        let responseHeaders: [String: String]?
        let errorDescriptionText: String?
        let errorLocalizedDescriptionText: String?
        let size: String?
        let modelIndex: Int
    }

    static let shared = NetworkSessionPersistenceManager()

    private let configuration = ModelConfiguration("DebugSwiftNetworkSessions")
    private var modelContainer: ModelContainer?
    private var activeSessionID: UUID?
    private var persistCountSinceLastPurge = 0

    private(set) var isEnabled = false
    private var retentionDays = 7

    private init() {}

    nonisolated static var isPersistenceEnabledPreference: Bool {
        UserDefaults.standard.bool(forKey: Preference.enabledKey)
    }

    nonisolated static var retentionDaysPreference: Int {
        let saved = UserDefaults.standard.integer(forKey: Preference.retentionDaysKey)
        return saved > 0 ? saved : Preference.defaultRetentionDays
    }

    func activateFromPreferences() {
        if Self.isPersistenceEnabledPreference {
            enable(retentionDays: Self.retentionDaysPreference)
        } else {
            disable()
        }
    }

    func applyFeatureEnabled(_ enabled: Bool) {
        if enabled {
            enable(retentionDays: Self.retentionDaysPreference)
        } else {
            disable()
        }
    }

    func enable(retentionDays: Int = 7) {
        self.retentionDays = max(1, retentionDays)
        UserDefaults.standard.set(true, forKey: Preference.enabledKey)
        UserDefaults.standard.set(self.retentionDays, forKey: Preference.retentionDaysKey)
        isEnabled = true
        _ = ensureContainer()
        beginSessionIfNeeded()
        purgeExpiredSessions(retentionDays: self.retentionDays)
    }

    func disable() {
        UserDefaults.standard.set(false, forKey: Preference.enabledKey)
        isEnabled = false
    }

    func beginSessionIfNeeded() {
        guard isEnabled else { return }
        guard let context = makeContext() else { return }
        guard activeSession == nil else { return }

        let session = NetworkSessionEntity(startedAt: Date())
        context.insert(session)
        save(context)
        activeSessionID = session.id
    }

    func persist(_ snapshot: RequestSnapshot) {
        guard isEnabled else { return }
        guard shouldPersist(snapshot) else { return }
        guard let context = makeContext() else { return }

        beginSessionIfNeeded()
        guard let session = activeSession else { return }

        let capturedAt = Date()
        let request = NetworkRequestEntity(
            url: snapshot.urlString,
            requestData: snapshot.requestData,
            responseData: snapshot.responseData,
            requestId: snapshot.requestId,
            method: snapshot.method,
            statusCode: snapshot.statusCode,
            mineType: snapshot.mineType,
            startTime: snapshot.startTime,
            endTime: snapshot.endTime,
            totalDuration: snapshot.totalDuration,
            isImage: snapshot.isImage,
            isEncrypted: snapshot.isEncrypted,
            requestHeadersData: Self.encodeHeaders(snapshot.requestHeaders),
            responseHeadersData: Self.encodeHeaders(snapshot.responseHeaders),
            errorDescriptionText: snapshot.errorDescriptionText,
            errorLocalizedDescriptionText: snapshot.errorLocalizedDescriptionText,
            size: snapshot.size,
            modelIndex: snapshot.modelIndex,
            mode: "http",
            capturedAt: capturedAt
        )

        request.session = session
        session.endedAt = capturedAt
        context.insert(request)
        save(context)

        persistCountSinceLastPurge += 1
        if persistCountSinceLastPurge >= 25 {
            persistCountSinceLastPurge = 0
            purgeExpiredSessions(retentionDays: retentionDays)
        }
    }

    func purgeExpiredSessions(retentionDays: Int = 7) {
        guard let context = makeContext() else { return }
        let safeRetentionDays = max(1, retentionDays)
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -safeRetentionDays, to: Date()) else {
            return
        }

        let descriptor = FetchDescriptor<NetworkSessionEntity>(
            predicate: #Predicate { $0.createdAt < cutoffDate }
        )

        if let sessions = try? context.fetch(descriptor) {
            sessions.forEach { context.delete($0) }
            save(context)
        }
    }

    func fetchSessions() -> [NetworkSessionEntity] {
        guard let context = makeContext() else { return [] }
        var descriptor = FetchDescriptor<NetworkSessionEntity>()
        descriptor.sortBy = [SortDescriptor(\.startedAt, order: .reverse)]
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchRequests(for sessionID: UUID) -> [NetworkRequestEntity] {
        guard let session = fetchSession(id: sessionID) else { return [] }
        return session.requests.sorted { $0.capturedAt < $1.capturedAt }
    }

    private var activeSession: NetworkSessionEntity? {
        guard let activeSessionID else { return nil }
        return fetchSession(id: activeSessionID)
    }

    private func ensureContainer() -> Bool {
        guard modelContainer == nil else { return true }

        do {
            modelContainer = try ModelContainer(
                for: NetworkSessionEntity.self,
                NetworkRequestEntity.self,
                configurations: configuration
            )
            return true
        } catch {
            modelContainer = nil
            return false
        }
    }

    private func makeContext() -> ModelContext? {
        guard ensureContainer(), let modelContainer else { return nil }
        return modelContainer.mainContext
    }

    private func save(_ context: ModelContext) {
        if context.hasChanges {
            try? context.save()
        }
    }

    private func fetchSession(id: UUID) -> NetworkSessionEntity? {
        guard let context = makeContext() else { return nil }
        let descriptor = FetchDescriptor<NetworkSessionEntity>(
            predicate: #Predicate { session in
                session.id == id
            }
        )
        return try? context.fetch(descriptor).first
    }

    private func shouldPersist(_ snapshot: RequestSnapshot) -> Bool {
        guard !isWebViewRequest(snapshot) else {
            return false
        }
        return !isFileResponse(snapshot)
    }

    private func isWebViewRequest(_ snapshot: RequestSnapshot) -> Bool {
        guard let headers = snapshot.responseHeaders else { return false }
        let source = headers.first { key, _ in
            key.lowercased() == "x-debugswift-source"
        }?.value.lowercased()
        return source == "wkwebview"
    }

    private func isFileResponse(_ snapshot: RequestSnapshot) -> Bool {
        if let mimeType = snapshot.mineType, Self.containsFileContentType(mimeType) {
            return true
        }

        guard let headers = snapshot.responseHeaders else { return false }
        let contentTypeValue = headers.first { key, _ in
            key.lowercased() == "content-type"
        }?.value ?? ""

        if Self.containsFileContentType(contentTypeValue) {
            return true
        }

        let contentDispositionValue = headers.first { key, _ in
            key.lowercased() == "content-disposition"
        }?.value.lowercased() ?? ""

        return contentDispositionValue.contains("attachment")
    }

    private static func containsFileContentType(_ value: String) -> Bool {
        let normalized = value.lowercased()
        let markers = [
            "image/",
            "video/",
            "audio/",
            "application/pdf",
            "application/zip",
            "application/x-zip-compressed",
            "application/octet-stream",
            "multipart/form-data",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument",
            "application/msword",
            "application/vnd.ms-powerpoint"
        ]
        return markers.contains { normalized.contains($0) }
    }

    private static func encodeHeaders(_ headers: [String: String]?) -> Data? {
        guard let headers else { return nil }
        return try? JSONSerialization.data(withJSONObject: headers, options: [])
    }

    nonisolated static func decodeHeaders(_ data: Data?) -> [String: Any]? {
        guard let data else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return json.reduce(into: [String: Any]()) { partialResult, item in
            partialResult[item.key] = item.value
        }
    }

    nonisolated static func enqueuePersist(from model: HttpModel) {
        let snapshot = RequestSnapshot(
            urlString: model.url?.absoluteString,
            requestData: model.requestData,
            responseData: model.responseData,
            requestId: model.requestId,
            method: model.method,
            statusCode: model.statusCode,
            mineType: model.mineType,
            startTime: model.startTime,
            endTime: model.endTime,
            totalDuration: model.totalDuration,
            isImage: model.isImage,
            isEncrypted: model.isEncrypted,
            requestHeaders: normalizedHeaders(model.requestHeaderFields),
            responseHeaders: normalizedHeaders(model.responseHeaderFields),
            errorDescriptionText: model.errorDescription,
            errorLocalizedDescriptionText: model.errorLocalizedDescription,
            size: model.size,
            modelIndex: model.index
        )

        Task { @MainActor in
            NetworkSessionPersistenceManager.shared.persist(snapshot)
        }
    }

    nonisolated private static func normalizedHeaders(_ headers: [String: Any]?) -> [String: String]? {
        guard let headers else { return nil }
        return headers.reduce(into: [String: String]()) { partialResult, item in
            partialResult[item.key] = String(describing: item.value)
        }
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
#endif
