// ReachabilityTests.swift
// Author: Matheus Gois
// Date: 21/12/2024
// Based on Given methodology

import XCTest
@testable import DebugSwift

class ReachabilityTests: XCTestCase {

    var reachability: Reachability!

    override func setUpWithError() throws {
        try super.setUpWithError()
        reachability = try Reachability()
    }

    override func tearDownWithError() throws {
        reachability = nil
        try super.tearDownWithError()
    }

    func testStartNotifier() throws {
        XCTAssertNoThrow(try reachability.startNotifier())
        XCTAssertTrue(reachability.notifierRunning)
    }

    func testStopNotifier() {
        reachability.stopNotifier()
        XCTAssertFalse(reachability.notifierRunning)
    }

    func testConnection() throws {
        try reachability.startNotifier()
        XCTAssertNotNil(reachability.connection)
    }

    func testGetSimpleNetworkType() {
        #if os(iOS)
        let networkType = reachability.getSimpleNetworkType()
        XCTAssertNotEqual(networkType, .unknown)
        #endif
    }

    func testGetNetworkType() {
        #if os(iOS)
        let networkType = reachability.getNetworkType()
        XCTAssertNotEqual(networkType, .unknown)
        #endif
    }
}
