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
        let requestHeadersData: Data?
        let responseHeadersData: Data?
        let responseHeaderLookup: [String: String]
        let shouldPersist: Bool
        let errorDescriptionText: String?
        let errorLocalizedDescriptionText: String?
        let size: String?
        let modelIndex: Int
    }

    struct SessionRecord: Sendable {
        let id: UUID
        let startedAt: Date
        let endedAt: Date?
        let requestCount: Int
    }

    struct RequestRecord: Sendable {
        let id: UUID
        let url: String?
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
        let requestHeadersData: Data?
        let responseHeadersData: Data?
        let errorDescriptionText: String?
        let errorLocalizedDescriptionText: String?
        let size: String?
        let modelIndex: Int
    }

    static let shared = NetworkSessionPersistenceManager()

    private var writeStore: NetworkSessionPersistenceStore?

    private(set) var isEnabled = false
    private var retentionDays = 7

    private init() {}

    static var isPersistenceEnabledPreference: Bool {
        UserDefaults.standard.bool(forKey: Preference.enabledKey)
    }

    static var retentionDaysPreference: Int {
        let saved = UserDefaults.standard.integer(forKey: Preference.retentionDaysKey)
        return saved > 0 ? saved : Preference.defaultRetentionDays
    }

    func activateFromPreferences() {
        Task {
            if Self.isPersistenceEnabledPreference {
                await enable(retentionDays: Self.retentionDaysPreference)
            } else {
                await disable()
            }
        }
    }

    func applyFeatureEnabled(_ enabled: Bool) async {
        if enabled {
            await enable(retentionDays: Self.retentionDaysPreference)
        } else {
            await disable()
        }
    }

    func enable(retentionDays: Int = 7) async {
        self.retentionDays = max(1, retentionDays)
        UserDefaults.standard.set(true, forKey: Preference.enabledKey)
        UserDefaults.standard.set(self.retentionDays, forKey: Preference.retentionDaysKey)
        isEnabled = true
        if writeStore == nil {
            writeStore = await NetworkSessionPersistenceStore.make()
        }
        guard let writeStore else { return }
        await writeStore.enable(retentionDays: self.retentionDays)
    }

    func setRetentionDays(_ days: Int) async {
        UserDefaults.standard.set(max(1, days), forKey: Preference.retentionDaysKey)
        retentionDays = Self.retentionDaysPreference

        if isEnabled {
            await purgeExpiredSessions(retentionDays: retentionDays)
        }
    }

    func disable() async {
        UserDefaults.standard.set(false, forKey: Preference.enabledKey)
        isEnabled = false
        guard let writeStore else { return }
        await writeStore.disable()
        self.writeStore = nil
    }

    func beginSessionIfNeeded() async {
        guard isEnabled else { return }
        guard let writeStore else { return }
        await writeStore.beginSessionIfNeeded()
    }

    func persist(_ snapshot: RequestSnapshot) async {
        guard isEnabled else { return }
        guard snapshot.shouldPersist else { return }
        guard let writeStore else { return }
        await writeStore.persist(snapshot)
    }

    func purgeExpiredSessions(retentionDays: Int = 7) async {
        guard let writeStore else { return }
        await writeStore.purgeExpiredSessions(retentionDays: retentionDays)
    }

    func fetchSessions() async -> [SessionRecord] {
        guard let writeStore else { return [] }
        return await writeStore.fetchSessions()
    }

    func activeSessionID() async -> UUID? {
        guard let writeStore else { return nil }
        return await writeStore.activeSessionID()
    }

    func fetchRequests(for sessionID: UUID) async -> [RequestRecord] {
        guard let writeStore else { return [] }
        return await writeStore.fetchRequests(for: sessionID)
    }

    func deleteSession(id: UUID) async {
        guard let writeStore else { return }
        await writeStore.deleteSession(id: id)
    }

    func deleteAllSessions() async {
        guard let writeStore else { return }
        await writeStore.deleteAllSessions()
    }

    nonisolated private static func containsFileContentType(_ value: String) -> Bool {
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

    nonisolated private static func encodeHeaders(_ headers: [String: String]?) -> Data? {
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
        let requestHeaders = normalizedHeaders(model.requestHeaderFields)
        let responseHeaders = normalizedHeaders(model.responseHeaderFields)
        let normalizedResponseHeaderLookup = lowercasedKeyHeaders(responseHeaders)
        let mimeType = model.mineType ?? ""
        let isWebViewSource = normalizedResponseHeaderLookup["x-debugswift-source"]?.lowercased() == "wkwebview"
        let contentTypeValue = normalizedResponseHeaderLookup["content-type"] ?? ""
        let contentDispositionValue = normalizedResponseHeaderLookup["content-disposition"]?.lowercased() ?? ""
        let isFileLikeResponse =
            containsFileContentType(mimeType) ||
            containsFileContentType(contentTypeValue) ||
            contentDispositionValue.contains("attachment")

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
            requestHeadersData: encodeHeaders(requestHeaders),
            responseHeadersData: encodeHeaders(responseHeaders),
            responseHeaderLookup: normalizedResponseHeaderLookup,
            shouldPersist: !isWebViewSource && !isFileLikeResponse,
            errorDescriptionText: model.errorDescription,
            errorLocalizedDescriptionText: model.errorLocalizedDescription,
            size: model.size,
            modelIndex: model.index
        )

        Task { @MainActor in
            await NetworkSessionPersistenceManager.shared.persist(snapshot)
        }
    }

    nonisolated private static func normalizedHeaders(_ headers: [String: Any]?) -> [String: String]? {
        guard let headers else { return nil }
        return headers.reduce(into: [String: String]()) { partialResult, item in
            partialResult[item.key] = String(describing: item.value)
        }
    }

    nonisolated private static func lowercasedKeyHeaders(_ headers: [String: String]?) -> [String: String] {
        guard let headers else { return [:] }
        return headers.reduce(into: [String: String]()) { partialResult, item in
            partialResult[item.key.lowercased()] = item.value
        }
    }
}
#endif
