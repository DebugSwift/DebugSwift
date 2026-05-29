//
//  NetworkSessionEntity.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 21/05/26.
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

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = createdAt
    }
}
#endif
