//
//  HARExportAdapter.swift
//  DebugSwift
//
//  Created by Matheus Gois (HAR Export) on 16/07/26.
//

import Foundation
import UIKit

// MARK: - HAR 1.2 / cURL Export — UIKit integration

/// Bridges the UIKit-bound `HttpModel` into the pure `HARCapture` shape and
/// drives sharing/export through `FileSharingManager`.
enum HARExportAdapter {

    /// Convert one `HttpModel` into a `HARCapture`. The UIKit-bound `HttpModel` can't
    /// cross into the pure encoder, so this mapping is the seam that keeps the
    /// encoder UIKit-free and macOS-testable. Redaction is on by default to avoid
    /// leaking credentials into exports.
    static func capture(from model: HttpModel, redact: Bool = true) -> HARCapture {
        let request = HARRequest(
            method: model.method ?? "GET",
            url: model.url?.absoluteString ?? "",
            headers: redact
                ? HAREncoder.redactHeaders(stringHeaders(model.requestHeaderFields))
                : stringHeaders(model.requestHeaderFields),
            body: bodyString(model.requestData)
        )
        let response = HARResponse(
            status: Int(model.statusCode ?? "0") ?? 0,
            headers: redact
                ? HAREncoder.redactHeaders(stringHeaders(model.responseHeaderFields))
                : stringHeaders(model.responseHeaderFields),
            body: bodyString(model.responseData)
        )
        return HARCapture(
            request: request,
            response: response,
            startedDateTime: Date(),
            time: Double(model.totalDuration ?? "0") ?? 0
        )
    }

    /// Export the models as a HAR 1.2 JSON file and present the share sheet,
    /// letting a developer move a capture off-device for inspection in DevTools.
    static func exportHAR(_ models: [HttpModel]) {
        let captures = models.map { capture(from: $0) }
        guard let json = HAREncoder.encodeJSON(captures) else { return }
        FileSharingManager.generateFileAndShare(text: json, fileName: "debugswift-export.har")
    }
    /// Copy a cURL command for a single model to the pasteboard so the request
    /// can be replayed in a terminal without retyping headers and body.
    static func copyCURL(_ model: HttpModel) {
        let capture = capture(from: model)
        UIPasteboard.general.string = HAREncoder.curlCommand(for: capture)
    }

    // MARK: - Private helpers

    private static func stringHeaders(_ headers: [String: Any]?) -> [String: String] {
        guard let headers else { return [:] }
        return headers.reduce(into: [String: String]()) { result, pair in
            result[pair.key] = String(describing: pair.value)
        }
    }

    private static func bodyString(_ data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8) ?? "<binary>"
    }
}
