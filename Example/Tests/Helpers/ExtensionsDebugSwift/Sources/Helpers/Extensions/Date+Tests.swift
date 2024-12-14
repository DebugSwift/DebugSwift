//
//  Date+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class DateTests: XCTestCase {

    func testMillisecondsSince1970() {
        // Given
        let date = Date(timeIntervalSince1970: 0)

        // When
        let milliseconds = date.millisecondsSince1970

        // Then
        XCTAssertEqual(milliseconds, 0, "The milliseconds since 1970 should be 0 for the epoch date")
    }

    func testInitWithMilliseconds() {
        // Given
        let milliseconds: Int64 = 0

        // When
        let date = Date(milliseconds: milliseconds)

        // Then
        XCTAssertEqual(date.timeIntervalSince1970, 0, "The date initialized with 0 milliseconds should be the epoch date")
    }
}
