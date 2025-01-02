//
//  ReachabilityManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

// final class ReachabilityManagerTests: XCTestCase {
//
//    func testConnectionWithReachableNetwork() {
//        // Given
//        let mockReachability = MockReachability(networkType: .wifi)
//        ReachabilityManager.reachability = mockReachability
//
//        // When
//        let connection = ReachabilityManager.connection
//
//        // Then
//        XCTAssertEqual(connection, .wifi, "The connection should be wifi")
//    }
//
//    func testConnectionWithUnreachableNetwork() {
//        // Given
//        let mockReachability = MockReachability(networkType: .none)
//        ReachabilityManager.reachability = mockReachability
//
//        // When
//        let connection = ReachabilityManager.connection
//
//        // Then
//        XCTAssertEqual(connection, .none, "The connection should be none")
//    }
//
//    func testConnectionWithUnknownNetwork() {
//        // Given
//        let mockReachability = MockReachability(networkType: .unknownTechnology)
//        ReachabilityManager.reachability = mockReachability
//
//        // When
//        let connection = ReachabilityManager.connection
//
//        // Then
//        XCTAssertEqual(connection, .unknownTechnology, "The connection should be unknownTechnology")
//    }
//
//    func testConnectionWithNilReachability() {
//        // Given
//        ReachabilityManager.reachability = nil
//
//        // When
//        let connection = ReachabilityManager.connection
//
//        // Then
//        XCTAssertEqual(connection, .unknownTechnology, "The connection should be unknownTechnology when reachability is nil")
//    }
// }
//
//// Mock class for Reachability
// class MockReachability: Reachability {
//    private let networkType: NetworkType
//
//    init(networkType: NetworkType) {
//        self.networkType = networkType
//    }
//
//    override func getNetworkType() -> NetworkType {
//        return networkType
//    }
// }
