//
//  HTTP.Model.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

public enum RequestSerializer: UInt {
    case json = 0
    case form
}

/// A single entry from a GraphQL response's `errors` array. GraphQL transports
/// failures inside an HTTP 200, so these are tracked separately from
/// `errorDescription` (transport failures) to keep the two distinguishable.
public struct HttpGraphQLError: Equatable, Sendable {
    public let message: String
    public let path: String?
    public let code: String?

    public init(message: String, path: String? = nil, code: String? = nil) {
        self.message = message
        self.path = path
        self.code = code
    }
}

public final class HttpModel: NSObject {
    public var url: URL?
    public var requestData: Data?
    public var responseData: Data?
    public var decryptedResponseData: Data?
    public var requestId: String?
    public var method: String?
    public var statusCode: String?
    public var mineType: String?
    public var startTime: String?
    public var endTime: String?
    public var totalDuration: String?
    public var isImage = false
    public var isEncrypted = false

    public var requestHeaderFields: [String: Any]?
    public var responseHeaderFields: [String: Any]?
    public var isTag = false
    public var isSelected = false
    public var requestSerializer: RequestSerializer = .json
    public var errorDescription: String?
    public var errorLocalizedDescription: String?
    public var size: String?
    public var index: Int = .zero
    public var id: String { String(index) }

    /// Optional custom title to display instead of the URL (e.g., GraphQL operation name)
    public var title: String?

    /// Errors returned in the GraphQL response's `errors` array. Non-empty means
    /// the operation failed even though the HTTP exchange (and status code) succeeded.
    public var graphQLErrors: [HttpGraphQLError] = []

    public var hasGraphQLErrors: Bool { !graphQLErrors.isEmpty }

    public override init() {
        super.init()
        self.statusCode = "0"
        self.url = URL(string: "")
    }

    public var isSuccess: Bool {
        (errorDescription == nil || errorDescription?.isEmpty == true) && graphQLErrors.isEmpty
    }
}
