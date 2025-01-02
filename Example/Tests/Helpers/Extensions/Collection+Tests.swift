//
//  Collection+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class CollectionTests: XCTestCase {

    func testSafeSubscriptWithValidIndex() {
        // Given
        let array = [1, 2, 3, 4, 5]

        // When
        let element = array[safe: 2]

        // Then
        XCTAssertEqual(element, 3, "The element at index 2 should be 3")
    }

    func testSafeSubscriptWithInvalidIndex() {
        // Given
        let array = [1, 2, 3, 4, 5]

        // When
        let element = array[safe: 10]

        // Then
        XCTAssertNil(element, "The element at index 10 should be nil")
    }

    func testSafeSubscriptWithEmptyCollection() {
        // Given
        let array: [Int] = []

        // When
        let element = array[safe: 0]

        // Then
        XCTAssertNil(element, "The element at index 0 should be nil for an empty array")
    }
}
