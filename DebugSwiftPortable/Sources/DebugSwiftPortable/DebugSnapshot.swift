import Foundation

public struct DebugSnapshot: Codable, Equatable, Sendable {
    public let appName: String
    public let platform: String
    public let events: [DebugEvent]

    public init(appName: String, platform: String, events: [DebugEvent]) {
        self.appName = appName
        self.platform = platform
        self.events = events
    }

    public func jsonString() throws -> String {
        let encodedEvents = events.map { event in
            """
            {"category":"\(Self.escape(event.category))","level":"\(event.level.rawValue)","message":"\(Self.escape(event.message))","timestamp":\(event.timestamp.timeIntervalSince1970)}
            """
        }.joined(separator: ",")

        return """
        {"appName":"\(Self.escape(appName))","events":[\(encodedEvents)],"platform":"\(Self.escape(platform))"}
        """
    }

    private static func escape(_ value: String) -> String {
        var result = ""
        for character in value {
            switch character {
            case "\\":
                result += "\\\\"
            case "\"":
                result += "\\\""
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "\t":
                result += "\\t"
            default:
                result.append(character)
            }
        }
        return result
    }
}
