//
//  GraphQLInspectorAdapter.swift
//  DebugSwift
//
//  Created by DebugSwift on 16/07/26.
//

import Foundation

// MARK: - #4 GraphQL Operation Inspector — integration helper

/// Bridges `HttpModel` to the pure `GraphQLInspector`, detecting GraphQL
/// requests and producing a structured view-model for `GraphQLDetailViewController`.
struct GraphQLDetail {

    /// Detected operation (query/mutation/subscription + name), or `nil`.
    let operation: GraphQLOperation?

    /// Parsed `variables` dictionary, or `nil`.
    let variables: [String: Any]?

    /// Split response `(data, errors)`, or `nil`.
    let response: (data: Any?, errors: Any?)?

    /// Pretty-printed query string, or `nil` if the request is not GraphQL.
    let query: String?
}

enum GraphQLInspectorAdapter {

    /// Detect whether an `HttpModel` is a GraphQL request: POST with
    /// `content-type: application/json` and a body containing a `query` field.
    static func isGraphQL(_ model: HttpModel) -> Bool {
        guard model.method?.uppercased() == "POST" else { return false }
        guard let headers = model.requestHeaderFields else { return false }
        let contentType = (headers["Content-Type"] as? String)
            ?? (headers["Content-type"] as? String)
            ?? (headers["content-type"] as? String)
            ?? ""
        return contentType.lowercased().contains("application/json")
            && requestBodyQuery(model) != nil
    }

    /// Build a `GraphQLDetail` from a captured request/response pair.
    static func detail(for model: HttpModel) -> GraphQLDetail {
        let body = requestBodyString(model)
        let operation = body.flatMap { GraphQLInspector.extractOperation(from: $0) }
        let variables = body.flatMap { GraphQLInspector.extractVariables(from: $0) }
        let response = responseBodyString(model).flatMap { GraphQLInspector.splitResponse($0) }
        let query = body.flatMap { requestBodyQuery($0) }
        return GraphQLDetail(operation: operation, variables: variables, response: response, query: query)
    }

    // MARK: - Private

    private static func requestBodyString(_ model: HttpModel) -> String? {
        guard let data = model.requestData, !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func responseBodyString(_ model: HttpModel) -> String? {
        let data = model.decryptedResponseData ?? model.responseData
        guard let data, !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func requestBodyQuery(_ model: HttpModel) -> String? {
        guard let body = requestBodyString(model) else { return nil }
        return requestBodyQuery(body)
    }

    private static func requestBodyQuery(_ body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json["query"] as? String
    }
}
