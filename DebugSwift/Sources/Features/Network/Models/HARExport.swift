//
//  HARExport.swift
//  DebugSwift
//
//  Created by Matheus Gois (HAR Export) on 16/07/26.
//

import Foundation

// MARK: - HAR 1.2 / cURL Export

/// A captured HTTP request/response pair, kept in a UIKit-agnostic shape so the
/// encoder stays fully testable on macOS without booting a simulator or host app.
public struct HARRequest: Equatable {
    public let method: String
    public let url: String
    public let headers: [String: String]
    public let body: String?

    public init(method: String, url: String, headers: [String: String], body: String? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public struct HARResponse: Equatable {
    public let status: Int
    public let headers: [String: String]
    public let body: String?

    public init(status: Int, headers: [String: String], body: String? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

public struct HARCapture: Equatable {
    public let request: HARRequest
    public let response: HARResponse
    public let startedDateTime: Date
    public let time: Double

    public init(request: HARRequest, response: HARResponse, startedDateTime: Date = Date(), time: Double = 0) {
        self.request = request
        self.response = response
        self.startedDateTime = startedDateTime
        self.time = time
    }
}

/// Pure encoder: `[HARCapture]` → HAR 1.2 dictionary, cURL command string,
/// and header redaction. Kept free of UIKit and URLSession so the export logic
/// can be unit-tested on macOS without a host app or simulator.
public enum HAREncoder {
    /// Credentials leaked into a shared HAR or cURL export are an active threat,
    /// so these header keys are masked by default to avoid shipping tokens.
    public static let defaultRedactedKeys: Set<String> = [
        "Authorization", "Cookie", "Set-Cookie"
    ]

    /// Encode captures into a HAR 1.2 dictionary — the 1.2 schema is the lingua
    /// franca of network tooling, so the output imports into Chrome DevTools,
    /// Charles and Proxyman without conversion.
    public static func encode(_ captures: [HARCapture]) -> [String: Any] {
        let entries = captures.map { capture -> [String: Any] in
            [
                "startedDateTime": ISO8601DateFormatter().string(from: capture.startedDateTime),
                "time": capture.time,
                "request": [
                    "method": capture.request.method,
                    "url": capture.request.url,
                    "headers": capture.request.headers.map { ["name": $0.key, "value": $0.value] },
                    "httpVersion": "HTTP/1.1",
                    "cookies": [],
                    "queryString": [],
                    "headersSize": -1,
                    "bodySize": capture.request.body?.count ?? 0
                ] as [String: Any],
                "response": [
                    "status": capture.response.status,
                    "statusText": "",
                    "httpVersion": "HTTP/1.1",
                    "headers": capture.response.headers.map { ["name": $0.key, "value": $0.value] },
                    "cookies": [],
                    "content": [
                        "size": capture.response.body?.count ?? 0,
                        "mimeType": capture.response.headers["Content-Type"] ?? "application/octet-stream"
                    ],
                    "redirectURL": "",
                    "headersSize": -1,
                    "bodySize": capture.response.body?.count ?? 0
                ] as [String: Any],
                "cache": [:],
                "timings": ["send": 0, "wait": capture.time, "receive": 0] as [String: Any]
            ] as [String: Any]
        }
        return [
            "log": [
                "version": "1.2",
                "creator": ["name": "DebugSwift", "version": "1.0"],
                "entries": entries
            ] as [String: Any]
        ]
    }

    /// Serialize the HAR dictionary to a JSON string; pretty-printing by default
    /// keeps exported files human-readable and diff-friendly for debugging.
    public static func encodeJSON(_ captures: [HARCapture], pretty: Bool = true) -> String? {
        let dict = encode(captures)
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: pretty ? [.prettyPrinted, .sortedKeys] : []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    /// Build a cURL command that reproduces the capture's request, so a developer
    /// can paste it into a terminal and replay the exact call outside the app.
    public static func curlCommand(for capture: HARCapture) -> String {
        var parts = ["curl", "-X", capture.request.method, "'\(capture.request.url)'"]
        for (key, value) in capture.request.headers {
            parts.append("-H '\(key): \(value)'")
        }
        if let body = capture.request.body, !body.isEmpty {
            parts.append("-d '\(body)'")
        }
        return parts.joined(separator: " ")
    }

    /// Replace sensitive header values with `<redacted>` so that exported HAR/cURL
    /// artifacts can be shared without leaking credentials by accident.
    public static func redactHeaders(
        _ headers: [String: String],
        keys: Set<String> = HAREncoder.defaultRedactedKeys
    ) -> [String: String] {
        headers.reduce(into: [String: String]()) { result, pair in
            result[pair.key] = keys.contains(pair.key) ? "<redacted>" : pair.value
        }
    }
}
