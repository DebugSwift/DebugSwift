//
//  NetworkSessionRewriteRuleBuilder.swift
//  DebugSwift
//
//  Created by Adjie Satryo on 16/05/26.
//

import Foundation

enum NetworkSessionRewriteRuleBuilder {
    static func makeRules(from models: [HttpModel]) -> [ResponseBodyRewriteRule] {
        struct RuleKey: Hashable {
            let urlPattern: String
            let method: HTTPMethod?
            let statusCode: Int?
            let responseBody: String
        }

        var processedKeys = Set<RuleKey>()
        var rules: [ResponseBodyRewriteRule] = []
        rules.reserveCapacity(models.count)

        for model in models {
            let urlPattern = model.url?.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !urlPattern.isEmpty else { continue }

            let methodText = model.method?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            let method = methodText.flatMap(HTTPMethod.init(rawValue:))

            let statusCodeText = model.statusCode?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let statusCode = statusCodeText.flatMap { Int($0) }

            let responseBody = model.decryptedResponseData?.formattedString() ?? model.responseData?.formattedString() ?? ""
            let ruleKey = RuleKey(
                urlPattern: urlPattern,
                method: method,
                statusCode: statusCode,
                responseBody: responseBody
            )

            if processedKeys.insert(ruleKey).inserted {
                rules.append(
                    ResponseBodyRewriteRule(
                        urlPattern: urlPattern,
                        responseBody: responseBody,
                        responseStatusCode: statusCode,
                        httpMethod: method,
                        isEnabled: true,
                        matchType: .exact
                    )
                )
            }
        }

        return rules
    }
}
