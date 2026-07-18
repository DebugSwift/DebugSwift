//
//  HARExportTests.swift
//  ExampleTests
//
//  Created by Matheus Gois on 16/07/26.
//

import XCTest
@testable import DebugSwift

final class HARExportTests: XCTestCase {

    // MARK: - Helpers

    private func makeCapture(
        method: String = "POST",
        url: String = "https://example.com/api",
        requestHeaders: [String: String] = ["Content-Type": "application/json"],
        requestBody: String? = "{\"key\":\"value\"}",
        responseStatus: Int = 200,
        responseHeaders: [String: String] = ["Content-Type": "application/json"],
        responseBody: String? = "{}",
        startedDateTime: Date = Date(timeIntervalSince1970: 1_700_000_000),
        time: Double = 0.5
    ) -> HARCapture {
        HARCapture(
            request: HARRequest(
                method: method,
                url: url,
                headers: requestHeaders,
                body: requestBody
            ),
            response: HARResponse(
                status: responseStatus,
                headers: responseHeaders,
                body: responseBody
            ),
            startedDateTime: startedDateTime,
            time: time
        )
    }

    private func makeHttpModel() -> HttpModel {
        let model = HttpModel()
        model.method = "POST"
        model.url = URL(string: "https://example.com")
        model.statusCode = "200"
        model.requestHeaderFields = [
            "Authorization": "Bearer token",
            "Content-Type": "application/json"
        ]
        model.responseHeaderFields = ["Content-Type": "application/json"]
        model.requestData = "{\"key\":\"value\"}".data(using: .utf8)
        model.responseData = "{}".data(using: .utf8)
        model.totalDuration = "0.5"
        return model
    }

    // MARK: - HAREncoder.encode Tests

    func testEncode_producesValidHARStructure() {
        let capture = makeCapture()
        let har = HAREncoder.encode([capture])

        guard let log = har["log"] as? [String: Any] else {
            return XCTFail("Expected top-level 'log' key")
        }

        XCTAssertEqual(log["version"] as? String, "1.2")

        guard let entries = log["entries"] as? [[String: Any]] else {
            return XCTFail("Expected 'entries' array")
        }
        XCTAssertEqual(entries.count, 1)

        guard let request = entries[0]["request"] as? [String: Any] else {
            return XCTFail("Expected entry 'request' dictionary")
        }
        XCTAssertEqual(request["method"] as? String, "POST")
        XCTAssertEqual(request["url"] as? String, "https://example.com/api")

        guard let creator = log["creator"] as? [String: Any] else {
            return XCTFail("Expected 'creator' dictionary")
        }
        XCTAssertEqual(creator["name"] as? String, "DebugSwift")
    }

    func testEncodeJSON_producesValidJSONString() {
        let capture = makeCapture()
        let json = HAREncoder.encodeJSON([capture])

        XCTAssertNotNil(json)
        XCTAssertTrue(json!.contains("\"version\""))
        XCTAssertTrue(json!.contains("1.2"))
    }

    // MARK: - HAREncoder.curlCommand Tests

    func testCurlCommand_includesMethodUrlHeadersBody() {
        let capture = makeCapture(
            method: "POST",
            url: "https://example.com/submit",
            requestHeaders: ["Content-Type": "application/json", "X-Custom": "abc"],
            requestBody: "{\"name\":\"test\"}"
        )
        let curl = HAREncoder.curlCommand(for: capture)

        XCTAssertTrue(curl.contains("curl"))
        XCTAssertTrue(curl.contains("-X POST"))
        XCTAssertTrue(curl.contains("'https://example.com/submit'"))
        XCTAssertTrue(curl.contains("-H 'Content-Type: application/json'"))
        XCTAssertTrue(curl.contains("-H 'X-Custom: abc'"))
        XCTAssertTrue(curl.contains("-d '{\"name\":\"test\"}'"))
    }

    func testCurlCommand_noBodyOmitsDataFlag() {
        let capture = makeCapture(
            method: "GET",
            url: "https://example.com/items",
            requestHeaders: [:],
            requestBody: nil
        )
        let curl = HAREncoder.curlCommand(for: capture)

        XCTAssertTrue(curl.contains("curl"))
        XCTAssertTrue(curl.contains("-X GET"))
        XCTAssertTrue(curl.contains("'https://example.com/items'"))
        XCTAssertFalse(curl.contains("-d"))
    }

    // MARK: - HAREncoder.redactHeaders Tests

    func testRedactHeaders_replacesSensitiveKeys() {
        let headers = [
            "Authorization": "Bearer token",
            "Cookie": "session=abc",
            "Set-Cookie": "session=abc",
            "Content-Type": "application/json",
            "X-Trace-Id": "123"
        ]
        let redacted = HAREncoder.redactHeaders(headers)

        XCTAssertEqual(redacted["Authorization"], "<redacted>")
        XCTAssertEqual(redacted["Cookie"], "<redacted>")
        XCTAssertEqual(redacted["Set-Cookie"], "<redacted>")
        XCTAssertEqual(redacted["Content-Type"], "application/json")
        XCTAssertEqual(redacted["X-Trace-Id"], "123")
    }

    func testRedactHeaders_customKeys() {
        let headers = [
            "Authorization": "Bearer token",
            "Content-Type": "application/json",
            "X-Secret": "secret-value",
            "Accept": "*/*"
        ]
        let redacted = HAREncoder.redactHeaders(
            headers,
            keys: ["X-Secret", "Accept"]
        )

        XCTAssertEqual(redacted["Authorization"], "Bearer token")
        XCTAssertEqual(redacted["Content-Type"], "application/json")
        XCTAssertEqual(redacted["X-Secret"], "<redacted>")
        XCTAssertEqual(redacted["Accept"], "<redacted>")
    }

    func testRedactHeaders_emptyHeaders() {
        let redacted = HAREncoder.redactHeaders([:])
        XCTAssertTrue(redacted.isEmpty)
    }

    // MARK: - HAREncoder.encode Edge Cases

    func testEncode_emptyArrayProducesValidStructure() {
        let har = HAREncoder.encode([])

        guard let log = har["log"] as? [String: Any] else {
            return XCTFail("Expected top-level 'log' key")
        }
        XCTAssertEqual(log["version"] as? String, "1.2")

        guard let entries = log["entries"] as? [[String: Any]] else {
            return XCTFail("Expected 'entries' array")
        }
        XCTAssertEqual(entries.count, 0)
    }

    // MARK: - Equatable & Field Preservation Tests

    func testHARRequest_equatable() {
        let request1 = HARRequest(
            method: "POST",
            url: "https://example.com",
            headers: ["Content-Type": "application/json"],
            body: "{\"key\":\"value\"}"
        )
        let request2 = HARRequest(
            method: "POST",
            url: "https://example.com",
            headers: ["Content-Type": "application/json"],
            body: "{\"key\":\"value\"}"
        )
        XCTAssertEqual(request1, request2)
    }

    func testCapture_timeAndStartedDateTime() {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let capture = makeCapture(startedDateTime: startDate, time: 1.5)

        XCTAssertEqual(capture.startedDateTime, startDate)
        XCTAssertEqual(capture.time, 1.5)

        let har = HAREncoder.encode([capture])
        guard let log = har["log"] as? [String: Any],
              let entries = log["entries"] as? [[String: Any]] else {
            return XCTFail("Expected valid HAR structure")
        }
        XCTAssertEqual(entries[0]["time"] as? Double, 1.5)
        XCTAssertNotNil(entries[0]["startedDateTime"] as? String)
    }

    // MARK: - HARExportAdapter Tests

    func testCapture_fromHttpModel_convertsFields() {
        let model = makeHttpModel()
        let capture = HARExportAdapter.capture(from: model, redact: false)

        XCTAssertEqual(capture.request.method, "POST")
        XCTAssertEqual(capture.request.url, "https://example.com")
        XCTAssertEqual(capture.request.body, "{\"key\":\"value\"}")
        XCTAssertEqual(capture.response.status, 200)
        XCTAssertEqual(capture.response.body, "{}")
        XCTAssertEqual(capture.time, 0.5)
        XCTAssertEqual(capture.request.headers["Content-Type"], "application/json")
    }

    func testCapture_fromHttpModel_redactsByDefault() {
        let model = makeHttpModel()
        let capture = HARExportAdapter.capture(from: model, redact: true)

        XCTAssertEqual(capture.request.headers["Authorization"], "<redacted>")
        XCTAssertEqual(capture.request.headers["Content-Type"], "application/json")
    }

    func testCapture_fromHttpModel_noRedactWhenDisabled() {
        let model = makeHttpModel()
        let capture = HARExportAdapter.capture(from: model, redact: false)

        XCTAssertEqual(capture.request.headers["Authorization"], "Bearer token")
        XCTAssertEqual(capture.request.headers["Content-Type"], "application/json")
    }
}
