//
//  RewriteRulesCSV.swift
//  DebugSwift
//
//  Created by Adjie Satryo Pamungkas on 06/03/26.
//

import Foundation

enum RewriteRulesCSV {
    static let expectedHeader = ["url_pattern", "response_status_code", "response_body"]

    static func export(rules: [ResponseBodyRewriteRule]) -> String {
        var lines: [String] = []
        lines.append(expectedHeader.joined(separator: ","))

        for rule in rules {
            let statusCode = rule.responseStatusCode.map(String.init) ?? ""
            let row = [
                csvEscaped(rule.urlPattern),
                csvEscaped(statusCode),
                csvEscaped(rule.responseBody),
            ].joined(separator: ",")
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    static func parse(_ text: String) throws -> [ResponseBodyRewriteRule] {
        let rows = try parseRows(text)
        guard let header = rows.first else {
            throw RewriteRulesCSVError.emptyFile
        }

        let normalizedHeader = header.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        guard normalizedHeader == expectedHeader else {
            throw RewriteRulesCSVError.invalidHeader
        }

        var rules: [ResponseBodyRewriteRule] = []
        for (index, row) in rows.dropFirst().enumerated() {
            if row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }

            guard row.count == expectedHeader.count else {
                throw RewriteRulesCSVError.invalidColumnCount(row: index + 2)
            }

            let urlPattern = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !urlPattern.isEmpty else {
                throw RewriteRulesCSVError.emptyURLPattern(row: index + 2)
            }

            let rawStatusCode = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let statusCode: Int?
            if rawStatusCode.isEmpty {
                statusCode = nil
            } else {
                guard let value = Int(rawStatusCode) else {
                    throw RewriteRulesCSVError.invalidStatusCode(row: index + 2)
                }
                statusCode = value
            }

            let responseBody = row[2]
            rules.append(
                ResponseBodyRewriteRule(
                    urlPattern: urlPattern,
                    responseBody: responseBody,
                    responseStatusCode: statusCode
                )
            )
        }

        return rules
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private static func parseRows(_ text: String) throws -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var didCloseQuotedField = false
        var rowNumber = 1

        let characters = Array(text)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                if inQuotes {
                    if index + 1 < characters.count, characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                        didCloseQuotedField = true
                    }
                } else {
                    guard field.isEmpty else {
                        throw RewriteRulesCSVError.invalidCSVFormat(row: rowNumber)
                    }
                    inQuotes = true
                }
            } else if character == ",", !inQuotes {
                row.append(field)
                field = ""
                didCloseQuotedField = false
            } else if (character == "\n" || character == "\r"), !inQuotes {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
                didCloseQuotedField = false
                rowNumber += 1

                if character == "\r", index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 1
                }
            } else if !inQuotes, didCloseQuotedField, !character.isWhitespace {
                throw RewriteRulesCSVError.invalidCSVFormat(row: rowNumber)
            } else {
                if !didCloseQuotedField {
                    field.append(character)
                }
            }

            index += 1
        }

        if inQuotes {
            throw RewriteRulesCSVError.invalidCSVFormat(row: rowNumber)
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }
}

enum RewriteRulesCSVError: LocalizedError, Equatable {
    case emptyFile
    case invalidHeader
    case invalidCSVFormat(row: Int)
    case invalidColumnCount(row: Int)
    case emptyURLPattern(row: Int)
    case invalidStatusCode(row: Int)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty."
        case .invalidHeader:
            return "Invalid CSV header. Expected: url_pattern,response_status_code,response_body"
        case .invalidCSVFormat(let row):
            return "Row \(row) has invalid CSV format."
        case .invalidColumnCount(let row):
            return "Row \(row) has an invalid number of columns."
        case .emptyURLPattern(let row):
            return "Row \(row) has an empty url_pattern value."
        case .invalidStatusCode(let row):
            return "Row \(row) has an invalid response_status_code value."
        }
    }
}
