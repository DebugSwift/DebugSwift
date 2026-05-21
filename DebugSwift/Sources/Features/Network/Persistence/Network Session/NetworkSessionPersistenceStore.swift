//
//  NetworkSessionPersistenceStore.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 21/05/26.
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@ModelActor
actor NetworkSessionPersistenceStore {
    private var activeSession: NetworkSessionEntity?
    private var pendingWriteCount = 0
    private var isEnabled = false
    private let saveBatchSize = 20

    func enable(retentionDays: Int) {
        let safeRetentionDays = max(1, retentionDays)
        isEnabled = true
        beginSessionIfNeededInternal()
        purgeExpiredSessionsInternal(retentionDays: safeRetentionDays)
    }

    func disable() {
        flushPendingWritesInternal()
        isEnabled = false
        activeSession = nil
    }

    func beginSessionIfNeeded() {
        beginSessionIfNeededInternal()
    }

    func persist(_ snapshot: NetworkSessionPersistenceManager.RequestSnapshot) {
        guard isEnabled, snapshot.shouldPersist else { return }
        beginSessionIfNeededInternal()
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
            requestHeadersData: snapshot.requestHeadersData,
            responseHeadersData: snapshot.responseHeadersData,
            errorDescriptionText: snapshot.errorDescriptionText,
            errorLocalizedDescriptionText: snapshot.errorLocalizedDescriptionText,
            size: snapshot.size,
            modelIndex: snapshot.modelIndex,
            mode: "http",
            capturedAt: capturedAt
        )

        request.session = session
        session.endedAt = capturedAt
        modelContext.insert(request)
        pendingWriteCount += 1
        saveInternal(force: false)
    }

    func purgeExpiredSessions(retentionDays: Int) {
        purgeExpiredSessionsInternal(retentionDays: retentionDays)
    }

    func fetchSessions() -> [NetworkSessionPersistenceManager.SessionRecord] {
        var descriptor = FetchDescriptor<NetworkSessionEntity>()
        descriptor.sortBy = [SortDescriptor(\.startedAt, order: .reverse)]
        guard let sessions = try? modelContext.fetch(descriptor) else { return [] }
        return sessions.map {
            NetworkSessionPersistenceManager.SessionRecord(
                id: $0.id,
                startedAt: $0.startedAt,
                endedAt: $0.endedAt,
                requestCount: $0.requests.count
            )
        }
    }

    func fetchRequests(for sessionID: UUID) -> [NetworkSessionPersistenceManager.RequestRecord] {
        let descriptor = FetchDescriptor<NetworkRequestEntity>(
            predicate: #Predicate { request in
                request.session?.id == sessionID
            },
            sortBy: [SortDescriptor(\.capturedAt, order: .forward)]
        )

        guard let requests = try? modelContext.fetch(descriptor) else { return [] }
        return requests.map {
            NetworkSessionPersistenceManager.RequestRecord(
                id: $0.id,
                url: $0.url,
                requestData: $0.requestData,
                responseData: $0.responseData,
                requestId: $0.requestId,
                method: $0.method,
                statusCode: $0.statusCode,
                mineType: $0.mineType,
                startTime: $0.startTime,
                endTime: $0.endTime,
                totalDuration: $0.totalDuration,
                isImage: $0.isImage,
                isEncrypted: $0.isEncrypted,
                requestHeadersData: $0.requestHeadersData,
                responseHeadersData: $0.responseHeadersData,
                errorDescriptionText: $0.errorDescriptionText,
                errorLocalizedDescriptionText: $0.errorLocalizedDescriptionText,
                size: $0.size,
                modelIndex: $0.modelIndex
            )
        }
    }

    private func beginSessionIfNeededInternal() {
        guard isEnabled else { return }
        guard activeSession == nil else { return }

        let session = NetworkSessionEntity(startedAt: Date())
        modelContext.insert(session)
        activeSession = session
        saveInternal(force: true)
    }

    private func purgeExpiredSessionsInternal(retentionDays: Int) {
        let safeRetentionDays = max(1, retentionDays)
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -safeRetentionDays, to: Date()) else {
            return
        }

        let descriptor = FetchDescriptor<NetworkSessionEntity>(
            predicate: #Predicate { $0.createdAt < cutoffDate }
        )

        if let sessions = try? modelContext.fetch(descriptor), !sessions.isEmpty {
            sessions.forEach { modelContext.delete($0) }
            saveInternal(force: true)
        }
    }

    private func saveInternal(force: Bool) {
        let shouldSaveNow = force || pendingWriteCount >= saveBatchSize
        if shouldSaveNow, modelContext.hasChanges {
            try? modelContext.save()
            pendingWriteCount = 0
        }
    }

    private func flushPendingWritesInternal() {
        saveInternal(force: true)
    }
}
#endif
