//
//  NetworkSessionRewriteRuleBuilder.swift
//  DebugSwift
//
//  Created by Adjie Satryo on 16/05/26.
//

import Foundation

enum NetworkSessionRewriteRuleBuilder {
    static func makeRules(from models: [HttpModel]) -> [ResponseBodyRewriteRule] {
        models.compactMap { model -> ResponseBodyRewriteRule? in
            let urlPattern = model.url?.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !urlPattern.isEmpty else { return nil }

            let methodText = model.method?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            let method = methodText.flatMap(HTTPMethod.init(rawValue:))

            let statusCodeText = model.statusCode?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let statusCode = statusCodeText.flatMap { Int($0) }

            return ResponseBodyRewriteRule(
                urlPattern: urlPattern,
                responseBody: model.decryptedResponseData?.formattedString() ?? model.responseData?.formattedString() ?? "",
                responseStatusCode: statusCode,
                httpMethod: method,
                isEnabled: true,
                matchType: .exact
            )
        }
    }
}
