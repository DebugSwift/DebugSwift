//
//  NetworkCustomRequestLoggingTests.swift
//  DebugSwift
//
//  Tests for DebugSwift.Network.logRequest(...) — manual logging of traffic
//  that bypasses URLSession (gRPC, custom sockets, etc.).
//

import XCTest
@testable import DebugSwift

final class NetworkCustomRequestLoggingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        HttpDatasource.shared.removeAll()
        DebugSwift.Network.shared.ignoredURLs = []
        DebugSwift.Network.shared.onlyURLs = []
    }

    override func tearDown() {
        HttpDatasource.shared.removeAll()
        DebugSwift.Network.shared.ignoredURLs = []
        DebugSwift.Network.shared.onlyURLs = []
        super.tearDown()
    }

    func testLogRequestStoresEntryWithAllFields() {
        let url = URL(string: "grpc://api.example.com/example.v1.UserService/GetUser")!
        let start = Date(timeIntervalSinceNow: -0.5)

        let stored = DebugSwift.Network.shared.logRequest(
            url: url,
            method: "POST",
            requestHeaders: ["grpc-accept-encoding": "gzip"],
            requestBody: Data("{\"id\":1}".utf8),
            responseStatusCode: 200,
            responseHeaders: ["content-type": "application/grpc"],
            responseBody: Data("{\"name\":\"Test\"}".utf8),
            startTime: start,
            endTime: Date()
        )

        XCTAssertTrue(stored)
        XCTAssertEqual(HttpDatasource.shared.httpModels.count, 1)

        let model = HttpDatasource.shared.httpModels[0]
        XCTAssertEqual(model.url, url)
        XCTAssertEqual(model.method, "POST")
        XCTAssertEqual(model.statusCode, "200")
        XCTAssertEqual(model.mineType, "application/grpc")
        XCTAssertEqual(model.requestHeaderFields?["grpc-accept-encoding"] as? String, "gzip")
        XCTAssertNotNil(model.requestData)
        XCTAssertNotNil(model.responseData)
        XCTAssertNotNil(model.totalDuration)
        XCTAssertTrue(model.isSuccess)
    }

    func testLogRequestMarksFailureWhenErrorProvided() {
        let error = NSError(
            domain: "io.grpc",
            code: 14,
            userInfo: [NSLocalizedDescriptionKey: "unavailable"]
        )

        let stored = DebugSwift.Network.shared.logRequest(
            url: URL(string: "grpc://api.example.com/example.v1.UserService/GetUser")!,
            method: "POST",
            responseStatusCode: 500,
            error: error
        )

        XCTAssertTrue(stored)
        let model = HttpDatasource.shared.httpModels[0]
        XCTAssertFalse(model.isSuccess)
        XCTAssertEqual(model.statusCode, "500")
    }

    func testLogRequestRespectsIgnoredURLs() {
        DebugSwift.Network.shared.ignoredURLs = ["*ignored.example.com*"]

        let stored = DebugSwift.Network.shared.logRequest(
            url: URL(string: "grpc://ignored.example.com/svc/Method")!
        )

        XCTAssertFalse(stored)
        XCTAssertTrue(HttpDatasource.shared.httpModels.isEmpty)
    }

    func testLogRequestRespectsOnlyURLs() {
        DebugSwift.Network.shared.onlyURLs = ["*allowed.example.com*"]

        let storedAllowed = DebugSwift.Network.shared.logRequest(
            url: URL(string: "grpc://allowed.example.com/svc/Method")!
        )
        let storedOther = DebugSwift.Network.shared.logRequest(
            url: URL(string: "grpc://other.example.com/svc/Method")!
        )

        XCTAssertTrue(storedAllowed)
        XCTAssertFalse(storedOther)
        XCTAssertEqual(HttpDatasource.shared.httpModels.count, 1)
    }

    func testLogRequestPostsReloadNotification() {
        let reload = expectation(
            forNotification: NSNotification.Name("reloadHttp_DebugSwift"),
            object: nil
        )

        DebugSwift.Network.shared.logRequest(
            url: URL(string: "https://api.example.com/v1/ping")!
        )

        wait(for: [reload], timeout: 1)
    }

    func testLogRequestDefaultsToZeroDurationWithoutStartTime() {
        DebugSwift.Network.shared.logRequest(
            url: URL(string: "https://api.example.com/v1/ping")!
        )

        let model = HttpDatasource.shared.httpModels[0]
        XCTAssertEqual(model.totalDuration, "0.0000 (s)")
    }
}
