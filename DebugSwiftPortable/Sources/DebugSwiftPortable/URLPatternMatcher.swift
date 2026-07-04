import Foundation

public enum URLPatternMatchStrategy: Sendable {
    case contains
    case full
}

public struct URLPatternMatcher: Sendable {
    public init() {}

    public func matches(
        _ value: String,
        wildcardPattern pattern: String,
        strategy: URLPatternMatchStrategy = .contains,
        caseInsensitive: Bool = true
    ) -> Bool {
        let escapedPattern = NSRegularExpression.escapedPattern(for: pattern)
        let wildcardRegex = escapedPattern
            .replacingOccurrences(of: "\\*", with: ".*")
            .replacingOccurrences(of: "\\?", with: ".")

        let regexPattern: String
        switch strategy {
        case .contains:
            regexPattern = wildcardRegex
        case .full:
            regexPattern = "^\(wildcardRegex)$"
        }

        var options: String.CompareOptions = [.regularExpression]
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }

        return value.range(of: regexPattern, options: options) != nil
    }
}
