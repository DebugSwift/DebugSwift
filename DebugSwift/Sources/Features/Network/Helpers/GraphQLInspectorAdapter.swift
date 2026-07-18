//
//  GraphQLInspectorAdapter.swift
//  DebugSwift
//
//  Created by Matheus Gois (GraphQL Inspector) on 16/07/26.
//

import Foundation

// MARK: - GraphQL Inspector Adapter

/// Bridges the captured `HttpModel` to the pure `GraphQLInspector` so the
/// UI layer never touches JSON parsing directly.
struct GraphQLDetail {

    /// Detected operation, shown as the headline row so a developer can identify
    /// the call at a glance.
    let operation: GraphQLOperation?

    /// Variables sent alongside the query, exposed so the actual arguments can
    /// be inspected without re-parsing the body.
    let variables: [String: Any]?

    /// Response split into `data`/`errors` so success versus failure is visible
    /// without scanning the raw payload.
    let response: (data: Any?, errors: Any?)?

    /// Pretty-printed query text, offered for copy/share so the exact operation
    /// can be reused outside the debugger.
    let query: String?
}

enum GraphQLInspectorAdapter {

    /// Detects GraphQL traffic so the detail UI can show an operation summary only
    /// for GraphQL POSTs — JSON body with a `query` field — and leave REST captures
    /// on their existing layout.
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

    /// Builds the full view-model in one call so the detail controller doesn't
    /// repeat parsing across multiple rows.
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
