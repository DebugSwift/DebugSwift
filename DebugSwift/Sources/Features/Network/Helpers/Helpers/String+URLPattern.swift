//
//  String+URLPattern.swift
//  DebugSwift
//
//  Created by Ajinumoto on 28/02/24.
//

import Foundation

enum URLPatternMatchStrategy {
    /// Pattern can match any substring of the value.
    case contains
    /// Pattern must match the whole value.
    case full
}

enum URLQueryPatternMatchStrategy {
    /// Query string is ignored.
    case ignore
    /// Pattern query items must exist in URL query items; extra URL query items are allowed.
    case subset
    /// Pattern query items and URL query items must match exactly (order-independent).
    case exact
}

extension String {
    /// Checks if the string matches a wildcard pattern with optional strategies for matching and case sensitivity.
    func matches(
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
        
        return range(of: regexPattern, options: options) != nil
    }
    
    /// Checks if the string matches any of the provided wildcard patterns with optional strategies for matching and case sensitivity.
    func matchesAny(
        wildcardPatterns patterns: [String],
        strategy: URLPatternMatchStrategy = .contains,
        caseInsensitive: Bool = true
    ) -> Bool {
        patterns.contains { pattern in
            matches(
                wildcardPattern: pattern,
                strategy: strategy,
                caseInsensitive: caseInsensitive
            )
        }
    }
}

extension URL {
    /// Checks if the URL matches a wildcard pattern with optional strategies for matching, query item matching, and case sensitivity.
    func matches(
        wildcardPattern pattern: String,
        strategy: URLPatternMatchStrategy = .contains,
        queryStrategy: URLQueryPatternMatchStrategy = .subset,
        caseInsensitive: Bool = true
    ) -> Bool {
        guard let parsedPattern = URLWildcardPattern(pattern) else {
            return absoluteString.matches(
                wildcardPattern: pattern,
                strategy: strategy,
                caseInsensitive: caseInsensitive
            )
        }
        
        if !parsedPattern.hasQuery {
            let valueToMatch = queryStrategy == .ignore
                ? absoluteStringWithoutQueryAndFragment
                : absoluteString
            
            return valueToMatch.matches(
                wildcardPattern: parsedPattern.basePattern,
                strategy: strategy,
                caseInsensitive: caseInsensitive
            )
        }
        
        let baseValue = absoluteStringWithoutQueryAndFragment
        guard baseValue.matches(
            wildcardPattern: parsedPattern.basePattern,
            strategy: strategy,
            caseInsensitive: caseInsensitive
        ) else {
            return false
        }
        
        return matchesQueryItems(
            parsedPattern.queryItems,
            strategy: queryStrategy,
            caseInsensitive: caseInsensitive
        )
    }
    
    /// Checks if the URL matches any of the provided wildcard patterns with optional strategies for matching, query item matching, and case sensitivity.
    func matchesAny(
        wildcardPatterns patterns: [String],
        strategy: URLPatternMatchStrategy = .contains,
        queryStrategy: URLQueryPatternMatchStrategy = .subset,
        caseInsensitive: Bool = true
    ) -> Bool {
        patterns.contains { pattern in
            matches(
                wildcardPattern: pattern,
                strategy: strategy,
                queryStrategy: queryStrategy,
                caseInsensitive: caseInsensitive
            )
        }
    }
    
    // Helper to get the absolute string without query and fragment for matching the base pattern
    private var absoluteStringWithoutQueryAndFragment: String {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            let withoutFragment = absoluteString.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? absoluteString
            return withoutFragment.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? withoutFragment
        }
        components.query = nil
        components.fragment = nil
        return components.string ?? absoluteString
    }
    
    private func matchesQueryItems(
        _ patternItems: [URLWildcardPattern.QueryItem],
        strategy: URLQueryPatternMatchStrategy,
        caseInsensitive: Bool
    ) -> Bool {
        switch strategy {
        case .ignore:
            return true
        case .subset:
            return matchQueryItems(
                patternItems: patternItems,
                urlItems: URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems ?? [],
                requireExactCount: false,
                caseInsensitive: caseInsensitive
            )
        case .exact:
            return matchQueryItems(
                patternItems: patternItems,
                urlItems: URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems ?? [],
                requireExactCount: true,
                caseInsensitive: caseInsensitive
            )
        }
    }
    
    // Backtracking algorithm to match pattern query items against URL query items, ensuring each pattern item matches a unique URL item.
    private func matchQueryItems(
        patternItems: [URLWildcardPattern.QueryItem],
        urlItems: [URLQueryItem],
        requireExactCount: Bool,
        caseInsensitive: Bool
    ) -> Bool {
        if requireExactCount, patternItems.count != urlItems.count {
            return false
        }
        if patternItems.isEmpty {
            return !requireExactCount || urlItems.isEmpty
        }
        
        var used = Array(repeating: false, count: urlItems.count)
        
        func backtrack(_ patternIndex: Int) -> Bool {
            if patternIndex == patternItems.count {
                return !requireExactCount || !used.contains(false)
            }
            
            let patternItem = patternItems[patternIndex]
            for urlIndex in urlItems.indices where !used[urlIndex] {
                if patternItem.matches(urlItem: urlItems[urlIndex], caseInsensitive: caseInsensitive) {
                    used[urlIndex] = true
                    if backtrack(patternIndex + 1) {
                        return true
                    }
                    used[urlIndex] = false
                }
            }
            return false
        }
        
        return backtrack(0)
    }
}

private struct URLWildcardPattern {
    struct QueryItem {
        let namePattern: String
        let valuePattern: String?
        let hasExplicitValue: Bool
        
        func matches(urlItem: URLQueryItem, caseInsensitive: Bool) -> Bool {
            guard urlItem.name.matches(
                wildcardPattern: namePattern,
                strategy: .full,
                caseInsensitive: caseInsensitive
            ) else {
                return false
            }
            
            guard hasExplicitValue else {
                return true
            }
            
            let urlValue = urlItem.value ?? ""
            return urlValue.matches(
                wildcardPattern: valuePattern ?? "",
                strategy: .full,
                caseInsensitive: caseInsensitive
            )
        }
    }
    
    let basePattern: String
    let queryItems: [QueryItem]
    let hasQuery: Bool
    
    init?(_ pattern: String) {
        guard !pattern.isEmpty else { return nil }
        
        let withoutFragment = pattern.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? pattern
        
        if let queryIndex = Self.queryDelimiterIndex(in: withoutFragment) {
            let rawBase = String(withoutFragment[..<queryIndex])
            basePattern = rawBase.isEmpty ? "*" : rawBase
            let queryStart = withoutFragment.index(after: queryIndex)
            let queryString = String(withoutFragment[queryStart...])
            hasQuery = true
            queryItems = Self.parseQueryItems(queryString)
        } else {
            basePattern = withoutFragment.isEmpty ? "*" : withoutFragment
            hasQuery = false
            queryItems = []
        }
    }
    
    // Finds the index of the first '?' that is followed by a valid query segment containing '=' or '&', ensuring it is not part of the base pattern.
    private static func queryDelimiterIndex(in pattern: String) -> String.Index? {
        var searchStart = pattern.startIndex
        
        while searchStart < pattern.endIndex,
              let questionIndex = pattern[searchStart...].firstIndex(of: "?") {
            let segmentStart = pattern.index(after: questionIndex)
            let segmentEnd = pattern[segmentStart...].firstIndex(of: "?") ?? pattern.endIndex
            let candidateQuerySegment = pattern[segmentStart..<segmentEnd]
            
            let looksLikeQueryPairs = candidateQuerySegment.contains("=") || candidateQuerySegment.contains("&")
            let looksLikeKeyOnlyQuery = !candidateQuerySegment.isEmpty && !candidateQuerySegment.contains("/")
            
            if looksLikeQueryPairs || looksLikeKeyOnlyQuery {
                return questionIndex
            }
            
            searchStart = segmentStart
        }
        
        return nil
    }
    
    // Parses the query string into an array of QueryItem, handling both key=value pairs and standalone keys, while decoding percent-encoded characters.
    private static func parseQueryItems(_ query: String) -> [QueryItem] {
        query.split(separator: "&", omittingEmptySubsequences: true).map { pair in
            let token = String(pair)
            if let equalIndex = token.firstIndex(of: "=") {
                let rawName = String(token[..<equalIndex])
                let rawValue = String(token[token.index(after: equalIndex)...])
                return QueryItem(
                    namePattern: rawName.removingPercentEncoding ?? rawName,
                    valuePattern: rawValue.removingPercentEncoding ?? rawValue,
                    hasExplicitValue: true
                )
            } else {
                let rawName = token
                return QueryItem(
                    namePattern: rawName.removingPercentEncoding ?? rawName,
                    valuePattern: nil,
                    hasExplicitValue: false
                )
            }
        }
    }
}
