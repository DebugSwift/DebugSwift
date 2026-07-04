import Foundation

public struct DebugEvent: Codable, Equatable, Sendable {
    public enum Level: String, Codable, Sendable {
        case info
        case warning
        case error
    }

    public let timestamp: Date
    public let level: Level
    public let category: String
    public let message: String

    public init(
        timestamp: Date = Date(),
        level: Level = .info,
        category: String,
        message: String
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
    }
}
