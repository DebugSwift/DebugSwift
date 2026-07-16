//
//  GraphQLInspector.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation

// MARK: - #4 GraphQL Operation Inspector (Foundation-only core)

/// The kind of GraphQL operation parsed from a request body.
public enum GraphQLOperation: Equatable {
    case query(name: String?)
    case mutation(name: String?)
    case subscription(name: String?)
}

/// Pure GraphQL inspector: parses operation name/type, extracts variables,
/// and splits a response into `data`/`errors`. Uses only `JSONSerialization`
/// and `NSRegularExpression` — no UIKit, no network.
public enum GraphQLInspector {

    /// Parse the GraphQL operation (type + name) from a request body string.
    /// Returns `nil` for anonymous or non-GraphQL bodies.
    public static func extractOperation(from body: String) -> GraphQLOperation? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let query = json["query"] as? String
        else { return nil }
        return parseOperationName(query)
    }

    /// Extract the `variables` dictionary from a request body. `nil` if absent
    /// or the body is not valid JSON.
    public static func extractVariables(from body: String) -> [String: Any]? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json["variables"] as? [String: Any]
    }

    /// Split a GraphQL response body into its `data` and `errors` components.
    /// Returns `nil` if the body is not valid JSON.
    public static func splitResponse(_ body: String) -> (data: Any?, errors: Any?)? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return (json["data"], json["errors"])
    }

    // MARK: - Private

    static func parseOperationName(_ query: String) -> GraphQLOperation? {
        let pattern = "(query|mutation|subscription)\\s+(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(query.startIndex..., in: query)
        guard let match = regex.firstMatch(in: query, options: [], range: range),
              match.numberOfRanges >= 3,
              let kindRange = Range(match.range(at: 1), in: query),
              let nameRange = Range(match.range(at: 2), in: query)
        else { return nil }
        let kind = String(query[kindRange])
        let name = String(query[nameRange])
        switch kind {
        case "query": return .query(name: name)
        case "mutation": return .mutation(name: name)
        case "subscription": return .subscription(name: name)
        default: return nil
        }
    }
}
