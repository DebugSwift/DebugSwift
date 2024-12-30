//
//  Data+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

extension Data {
    func formattedSize() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB, .useGB]

        return byteCountFormatter.string(fromByteCount: Int64(count))
    }

    func formattedString() -> String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            if let formattedString = String(data: jsonData, encoding: .utf8) {
                return formattedString
            }
        } catch {}

        // Can adjust to get the image and the jsons formatted
        return String(data: self, encoding: .utf8) ?? String(decoding: self, as: UTF8.self)
    }
}

extension [String: String] {
    func formattedCurlString() -> String {
        map { "\($0.key): \($0.value)" }.joined(separator: "\\n-H ")
    }
}

extension [String: Any] {
    func formattedCurlString() -> String {
        return map { key, value in
            "\(key): \(value)"
        }.joined(separator: "\\n-H ")
    }
}

extension Data {
    func formattedCurlString() -> String {
        if let string = String(data: self, encoding: .utf8) {
            return string.escapedForCurl()
        }
        return ""
    }
}

extension String {
    func escapedForCurl() -> String {
        replacingOccurrences(of: "'", with: "\\'")
    }
}

extension URLRequest {
    func formattedCurlString() -> String {
        var curlCommand = "curl -X \(httpMethod ?? "")"

        if let headers = allHTTPHeaderFields, !headers.isEmpty {
            curlCommand += " -H '\(headers.formattedCurlString())'"
        }

        if let bodyData = httpBody {
            curlCommand += " -d '\(bodyData.formattedCurlString())'"
        }

        if let url {
            curlCommand += " \(url.absoluteString)"
        }

        return curlCommand
    }
}
