//
//  CustomHTTPProtocolSSETests.swift
//  DebugSwift
//
//  Tests that server-sent-event streams are not intercepted.
//

import XCTest
@testable import DebugSwift

final class CustomHTTPProtocolSSETests: XCTestCase {
    func testDoesNotInterceptServerSentEventRequests() {
        var request = URLRequest(url: URL(string: "https://api.example.com/v1/events")!)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        XCTAssertFalse(CustomHTTPProtocol.canInit(with: request))
    }

    func testInterceptsRegularHTTPSRequests() {
        let request = URLRequest(url: URL(string: "https://api.example.com/v1/ping")!)
        XCTAssertTrue(CustomHTTPProtocol.canInit(with: request))
    }
}
