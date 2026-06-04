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
    private enum StoreConfiguration {
        static let name = "DebugSwiftNetworkSessions"

        static var url: URL {
            let fileManager = FileManager.default
            let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            return baseURL
                .appendingPathComponent("DebugSwift", isDirectory: true)
                .appendingPathComponent("\(name).store", isDirectory: false)
        }
    }

    private var activeSession: NetworkSessionEntity?
    private var pendingWriteCount = 0
    private var isEnabled = false
    private var saveBatchSize = 2

    nonisolated static func make() async -> NetworkSessionPersistenceStore? {
        await Task.detached(priority: .utility) {
            do {
                return try makeStore()
            } catch {
                Debug.print("DebugSwift network session persistence failed to open: \(error)")
                resetStoreFiles()
                do {
                    return try makeStore()
                } catch {
                    Debug.print("DebugSwift network session persistence failed after reset: \(error)")
                    return nil
                }
            }
        }.value
    }

    nonisolated private static func makeStore() throws -> NetworkSessionPersistenceStore {
        let storeURL = StoreConfiguration.url
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let configuration = ModelConfiguration(
            StoreConfiguration.name,
            url: storeURL
        )
        let modelContainer = try ModelContainer(
            for: NetworkSessionEntity.self,
            NetworkRequestEntity.self,
            configurations: configuration
        )
        return NetworkSessionPersistenceStore(modelContainer: modelContainer)
    }

    nonisolated private static func resetStoreFiles() {
        let storeURL = StoreConfiguration.url
        let sidecarURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        sidecarURLs.forEach {
            do {
                try FileManager.default.removeItem(at: $0)
            } catch {
                guard (error as NSError).code != NSFileNoSuchFileError else { return }
                Debug.print("DebugSwift network session persistence failed to remove store file \($0.lastPathComponent): \(error)")
            }
        }
    }

    func enable(retentionDays: Int, batchSize: Int) {
        isEnabled = true
        saveBatchSize = batchSize
        purgeExpiredSessionsInternal(retentionDays: retentionDays)
    }

    func disable() {
        flushPendingWritesInternal()
        isEnabled = false
        activeSession = nil
    }

    func persist(_ snapshot: NetworkSessionPersistenceManager.RequestSnapshot) {
        guard isEnabled, snapshot.shouldPersist else { return }
        beginSessionIfNeeded()
        guard let session = activeSession else { return }

        let capturedAt = Date()
        let request = NetworkRequestEntity(
            sessionID: session.id,
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
            let sessionID = $0.id
            let requestDescriptor = FetchDescriptor<NetworkRequestEntity>(
                predicate: #Predicate { request in
                    request.sessionID == sessionID
                }
            )
            let requestCount = (try? modelContext.fetchCount(requestDescriptor)) ?? 0

            return NetworkSessionPersistenceManager.SessionRecord(
                id: $0.id,
                startedAt: $0.startedAt,
                endedAt: $0.endedAt,
                requestCount: requestCount
            )
        }
    }

    func activeSessionID() -> UUID? {
        activeSession?.id
    }

    func fetchRequests(for sessionID: UUID) -> [NetworkSessionPersistenceManager.RequestRecord] {
        let descriptor = FetchDescriptor<NetworkRequestEntity>(
            predicate: #Predicate { request in
                request.sessionID == sessionID
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

    func deleteSession(id: UUID) {
        if activeSession?.id == id {
            activeSession = nil
        }

        deleteRequests(for: id)

        let descriptor = FetchDescriptor<NetworkSessionEntity>(
            predicate: #Predicate { session in
                session.id == id
            }
        )

        if let session = try? modelContext.fetch(descriptor).first {
            modelContext.delete(session)
            saveInternal(force: true)
        }
    }

    func deleteAllSessions() {
        activeSession = nil

        let requestDescriptor = FetchDescriptor<NetworkRequestEntity>()
        if let requests = try? modelContext.fetch(requestDescriptor) {
            requests.forEach { modelContext.delete($0) }
        }

        let sessionDescriptor = FetchDescriptor<NetworkSessionEntity>()
        if let sessions = try? modelContext.fetch(sessionDescriptor) {
            sessions.forEach { modelContext.delete($0) }
        }

        saveInternal(force: true)
    }

    private func beginSessionIfNeeded() {
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
            sessions.forEach { session in
                deleteRequests(for: session.id)
                modelContext.delete(session)
            }
            saveInternal(force: true)
        }
    }

    private func deleteRequests(for sessionID: UUID) {
        let requestDescriptor = FetchDescriptor<NetworkRequestEntity>(
            predicate: #Predicate { request in
                request.sessionID == sessionID
            }
        )
        if let requests = try? modelContext.fetch(requestDescriptor) {
            requests.forEach { modelContext.delete($0) }
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
